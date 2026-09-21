// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Admin Routes
// GET  /api/admin/stats          - Platform metrics
// GET  /api/admin/audit-logs     - Security audit log
// GET  /api/admin/login-attempts - Failed login attempts
// GET  /api/admin/users          - All users
// PUT  /api/admin/users/:id/suspend - Suspend/unsuspend a user
// ─────────────────────────────────────────────────────────────────────────────

import express from "express";
import bcrypt from "bcryptjs";
import prisma from "../db/prisma.js";
import { authenticateToken, requireRoles, auditLog } from "../middleware/auth.js";

const router = express.Router();

// All admin routes require authentication + PLATFORM_ADMIN role
router.use(authenticateToken);
router.use(requireRoles("PLATFORM_ADMIN"));

// ── GET /api/admin/stats ──────────────────────────────────────────────────
router.get("/stats", async (req, res) => {
  try {
    const [
      totalUsers,
      totalPatients,
      totalPharmacies,
      totalOrders,
      pendingOrders,
      completedOrders,
      totalRevenue,
      suspiciousEvents,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { role: "PATIENT" } }),
      prisma.pharmacy.count({ where: { isApproved: true } }),
      prisma.order.count(),
      prisma.order.count({ where: { status: "PENDING" } }),
      prisma.order.count({ where: { status: "DELIVERED" } }),
      prisma.order.aggregate({ _sum: { totalAmount: true } }),
      prisma.auditLog.count({ where: { isSuspicious: true } }),
    ]);

    res.json({
      users: { total: totalUsers, patients: totalPatients },
      pharmacies: { approved: totalPharmacies },
      orders: {
        total: totalOrders,
        pending: pendingOrders,
        completed: completedOrders,
      },
      revenue: { total: totalRevenue._sum.totalAmount || 0 },
      security: { suspiciousEvents },
    });
  } catch (error) {
    console.error("Admin stats error:", error);
    res.status(500).json({ error: "Failed to load stats" });
  }
});

// ── GET /api/admin/audit-logs ─────────────────────────────────────────────
router.get("/audit-logs", async (req, res) => {
  try {
    const { page = 1, limit = 50, suspicious } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = suspicious === "true" ? { isSuspicious: true } : {};

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip,
        take: parseInt(limit),
      }),
      prisma.auditLog.count({ where }),
    ]);

    res.json({
      logs,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit)),
    });
  } catch (error) {
    console.error("Audit logs error:", error);
    res.status(500).json({ error: "Failed to load audit logs" });
  }
});

// ── GET /api/admin/login-attempts ────────────────────────────────────────
router.get("/login-attempts", async (req, res) => {
  try {
    const { page = 1, limit = 50, failedOnly } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = failedOnly === "true" ? { success: false } : {};

    const [attempts, total] = await Promise.all([
      prisma.loginAttempt.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip,
        take: parseInt(limit),
      }),
      prisma.loginAttempt.count({ where }),
    ]);

    res.json({ attempts, total, page: parseInt(page) });
  } catch (error) {
    console.error("Login attempts error:", error);
    res.status(500).json({ error: "Failed to load login attempts" });
  }
});

// ── GET /api/admin/users ─────────────────────────────────────────────────
router.get("/users", async (req, res) => {
  try {
    const { role, page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = role ? { role } : {};

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          fullName: true,
          phone: true,
          role: true,
          isApproved: true,
          createdAt: true,
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: parseInt(limit),
      }),
      prisma.user.count({ where }),
    ]);

    res.json({ users, total, page: parseInt(page) });
  } catch (error) {
    console.error("Users error:", error);
    res.status(500).json({ error: "Failed to load users" });
  }
});

// ── PUT /api/admin/users/:id/suspend ─────────────────────────────────────
router.put("/users/:id/suspend", async (req, res) => {
  try {
    const { id } = req.params;
    const { suspend, reason } = req.body;

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ error: "User not found" });

    const updatedUser = await prisma.user.update({
      where: { id },
      data: { isApproved: !suspend },
    });

    await auditLog(req, {
      action: suspend ? "USER_SUSPENDED" : "USER_REACTIVATED",
      tableName: "User",
      recordId: id,
      oldValue: { isApproved: user.isApproved },
      newValue: { isApproved: !suspend, reason },
      isSuspicious: suspend,
    });

    res.json({
      message: suspend ? "User suspended" : "User reactivated",
      user: { id: updatedUser.id, email: updatedUser.email, isApproved: updatedUser.isApproved },
    });
  } catch (error) {
    console.error("Suspend user error:", error);
    res.status(500).json({ error: "Failed to update user" });
  }
});

// ── POST /api/admin/users (Create User) ──────────────────────────────────
router.post("/users", async (req, res) => {
  try {
    const { email, password, fullName, phone, role = "PATIENT", isApproved = true, pharmacyId } = req.body;

    if (!email || !password || !fullName) {
      return res.status(400).json({ error: "Email, password, and full name are required" });
    }

    const existingUser = await prisma.user.findUnique({
      where: { email: email.toLowerCase().trim() },
    });
    if (existingUser) {
      return res.status(400).json({ error: "Email already registered" });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const validRoles = ["PATIENT", "PHARMACY_ADMIN", "CASHIER", "DELIVERY_AGENT", "PLATFORM_ADMIN"];
    const assignedRole = validRoles.includes(role) ? role : "PATIENT";

    const user = await prisma.user.create({
      data: {
        email: email.toLowerCase().trim(),
        passwordHash,
        fullName: fullName.trim(),
        phone: phone ? phone.trim() : null,
        role: assignedRole,
        isApproved: Boolean(isApproved),
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        role: true,
        isApproved: true,
        createdAt: true,
      },
    });

    if (pharmacyId && (assignedRole === "PHARMACY_ADMIN" || assignedRole === "CASHIER")) {
      await prisma.pharmacyStaff.create({
        data: {
          userId: user.id,
          pharmacyId,
          role: assignedRole,
        },
      });
    }

    await auditLog(req, {
      action: "USER_CREATED_BY_ADMIN",
      tableName: "User",
      recordId: user.id,
      newValue: { email: user.email, role: user.role, fullName: user.fullName },
    });

    res.status(201).json({ message: "User created successfully", user });
  } catch (error) {
    console.error("Create user error:", error);
    res.status(500).json({ error: "Failed to create user" });
  }
});

// ── PUT /api/admin/users/:id (Update User) ───────────────────────────────
router.put("/users/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, phone, role, isApproved, password } = req.body;

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ error: "User not found" });

    const data = {};
    if (fullName !== undefined) data.fullName = fullName.trim();
    if (phone !== undefined) data.phone = phone ? phone.trim() : null;
    if (role !== undefined) {
      const validRoles = ["PATIENT", "PHARMACY_ADMIN", "CASHIER", "DELIVERY_AGENT", "PLATFORM_ADMIN"];
      if (validRoles.includes(role)) data.role = role;
    }
    if (isApproved !== undefined) data.isApproved = Boolean(isApproved);
    if (password && password.trim().length >= 6) {
      data.passwordHash = await bcrypt.hash(password.trim(), 10);
    }

    const updatedUser = await prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        role: true,
        isApproved: true,
        createdAt: true,
      },
    });

    await auditLog(req, {
      action: "USER_UPDATED_BY_ADMIN",
      tableName: "User",
      recordId: id,
      oldValue: { role: user.role, isApproved: user.isApproved },
      newValue: { role: updatedUser.role, isApproved: updatedUser.isApproved },
    });

    res.json({ message: "User updated successfully", user: updatedUser });
  } catch (error) {
    console.error("Update user error:", error);
    res.status(500).json({ error: "Failed to update user" });
  }
});

// ── DELETE /api/admin/users/:id (Delete User) ────────────────────────────
router.delete("/users/:id", async (req, res) => {
  try {
    const { id } = req.params;

    if (id === req.user.id) {
      return res.status(400).json({ error: "Cannot delete your own account" });
    }

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ error: "User not found" });

    await prisma.pharmacyStaff.deleteMany({ where: { userId: id } });
    await prisma.user.delete({ where: { id } });

    await auditLog(req, {
      action: "USER_DELETED_BY_ADMIN",
      tableName: "User",
      recordId: id,
      oldValue: { email: user.email, fullName: user.fullName, role: user.role },
    });

    res.json({ message: "User deleted successfully" });
  } catch (error) {
    console.error("Delete user error:", error);
    res.status(500).json({ error: "Failed to delete user" });
  }
});

export default router;
