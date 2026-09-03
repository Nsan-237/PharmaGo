import express from "express";
import prisma from "../db/prisma.js";
import { authenticateToken, requireRoles } from "../middleware/auth.js";

const router = express.Router();

// Require Super Admin for all routes in this router
router.use(authenticateToken, requireRoles("PLATFORM_ADMIN"));

// Get Super Admin System Dashboard Metrics
router.get("/metrics", async (req, res) => {
  try {
    const totalUsers = await prisma.user.count();
    const totalPharmacies = await prisma.pharmacy.count();
    const pendingPharmacies = await prisma.pharmacy.count({ where: { isApproved: false } });
    const totalOrders = await prisma.order.count();
    const totalRevenue = await prisma.order.aggregate({
      _sum: { totalAmount: true },
      where: { status: "DELIVERED" },
    });

    const recentOrders = await prisma.order.findMany({
      take: 5,
      orderBy: { createdAt: "desc" },
      include: {
        pharmacy: { select: { name: true } },
        patient: { select: { fullName: true } },
      },
    });

    res.json({
      metrics: {
        totalUsers,
        totalPharmacies,
        pendingPharmacies,
        totalOrders,
        totalRevenue: totalRevenue._sum.totalAmount || 0,
      },
      recentOrders,
    });
  } catch (error) {
    console.error("Admin Metrics Error:", error);
    res.status(500).json({ error: "Failed to fetch admin metrics" });
  }
});

// Approve or Reject Pharmacy Onboarding Application
router.put("/pharmacies/:id/approval", async (req, res) => {
  try {
    const { id } = req.params;
    const { isApproved } = req.body;

    const pharmacy = await prisma.pharmacy.update({
      where: { id },
      data: { isApproved: isApproved === true || isApproved === "true" },
    });

    res.json({ message: `Pharmacy ${isApproved ? "approved" : "rejected"}`, pharmacy });
  } catch (error) {
    console.error("Approve Pharmacy Error:", error);
    res.status(500).json({ error: "Failed to update pharmacy approval status" });
  }
});

// Get all registered users
router.get("/users", async (req, res) => {
  try {
    const users = await prisma.user.findMany({
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
    });

    res.json({ users });
  } catch (error) {
    console.error("Fetch Users Error:", error);
    res.status(500).json({ error: "Failed to fetch users" });
  }
});

export default router;
