// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Admin Routes
// GET  /api/admin/stats          - Platform metrics
// GET  /api/admin/audit-logs     - Security audit log
// GET  /api/admin/login-attempts - Failed login attempts
// GET  /api/admin/users          - All users
// PUT  /api/admin/users/:id/suspend - Suspend/unsuspend a user
// ─────────────────────────────────────────────────────────────────────────────

import express from "express";
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

export default router;
