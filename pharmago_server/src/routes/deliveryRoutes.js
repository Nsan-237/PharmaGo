// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Delivery Agent Routes
// Handles all delivery agent operations: accepting orders, status updates,
// chat messages, availability toggle, and daily earnings stats.
// ─────────────────────────────────────────────────────────────────────────────

import express from "express";
import prisma from "../db/prisma.js";
import { authenticateToken, requireRoles } from "../middleware/auth.js";

const router = express.Router();

// ── GET /api/agent/orders ─────────────────────────────────────────────────
// Get deliveries assigned to this agent + available orders (READY_FOR_PICKUP)
router.get("/orders", authenticateToken, requireRoles("DELIVERY_AGENT", "PLATFORM_ADMIN"), async (req, res) => {
  try {
    const agentId = req.user.id;

    // Orders assigned to this agent (IN_TRANSIT or DELIVERED)
    let myOrders = await prisma.order.findMany({
      where: {
        deliveryAgentId: agentId,
        status: { in: ["IN_TRANSIT", "DELIVERED"] },
      },
      include: {
        items: true,
        patient: { select: { id: true, fullName: true, phone: true } },
        pharmacy: { select: { id: true, name: true, phone: true, address: true } },
      },
      orderBy: { updatedAt: "desc" },
    });

    if (myOrders.length === 0) {
      myOrders = await prisma.order.findMany({
        where: {
          status: { in: ["IN_TRANSIT", "DELIVERED"] },
        },
        include: {
          items: true,
          patient: { select: { id: true, fullName: true, phone: true } },
          pharmacy: { select: { id: true, name: true, phone: true, address: true } },
        },
        orderBy: { updatedAt: "desc" },
      });
    }

    // Orders available for delivery (unassigned customer orders)
    let availableOrders = await prisma.order.findMany({
      where: {
        status: { in: ["PENDING", "CONFIRMED", "PREPARING", "READY_FOR_PICKUP"] },
        deliveryAgentId: null,
        deliveryAddress: { not: "" },
      },
      include: {
        items: true,
        patient: { select: { id: true, fullName: true, phone: true } },
        pharmacy: { select: { id: true, name: true, phone: true, address: true } },
      },
      orderBy: { createdAt: "desc" },
    });

    if (availableOrders.length === 0) {
      availableOrders = await prisma.order.findMany({
        where: {
          deliveryAddress: { not: "" },
          status: { in: ["PENDING", "CONFIRMED", "PREPARING", "READY_FOR_PICKUP"] },
        },
        include: {
          items: true,
          patient: { select: { id: true, fullName: true, phone: true } },
          pharmacy: { select: { id: true, name: true, phone: true, address: true } },
        },
        orderBy: { createdAt: "desc" },
      });
    }

    res.json({
      assigned: myOrders.filter(o => o.status === "IN_TRANSIT"),
      available: availableOrders,
      delivered: myOrders.filter(o => o.status === "DELIVERED"),
    });
  } catch (error) {
    console.error("Agent Orders Error:", error);
    res.status(500).json({ error: "Failed to fetch agent orders" });
  }
});

// ── PATCH /api/agent/orders/:id/accept ────────────────────────────────────
// Agent accepts an available order → assigns themselves + sets IN_TRANSIT
router.patch("/orders/:id/accept", authenticateToken, requireRoles("DELIVERY_AGENT"), async (req, res) => {
  try {
    const { id } = req.params;
    const agentId = req.user.id;

    const order = await prisma.order.findUnique({ where: { id } });
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.deliveryAgentId && order.deliveryAgentId !== agentId) {
      return res.status(409).json({ error: "Order already taken by another agent" });
    }

    const updated = await prisma.order.update({
      where: { id },
      data: {
        deliveryAgentId: agentId,
        status: "IN_TRANSIT",
      },
      include: {
        items: true,
        patient: { select: { id: true, fullName: true, phone: true } },
        pharmacy: { select: { id: true, name: true, phone: true, address: true } },
      },
    });

    // Log delivery action
    await prisma.deliveryLog.create({
      data: {
        orderId: id,
        agentId,
        lat: 0,
        lng: 0,
      },
    });

    console.log(`🛵 Agent ${req.user.fullName} accepted order ${order.orderNumber}`);
    res.json({ message: "Order accepted — En route!", order: updated });
  } catch (error) {
    console.error("Accept Order Error:", error);
    res.status(500).json({ error: "Failed to accept order" });
  }
});

// ── PATCH /api/agent/orders/:id/deliver ───────────────────────────────────
// Agent marks order as delivered
router.patch("/orders/:id/deliver", authenticateToken, requireRoles("DELIVERY_AGENT"), async (req, res) => {
  try {
    const { id } = req.params;
    const agentId = req.user.id;

    const order = await prisma.order.findUnique({ where: { id } });
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.deliveryAgentId !== agentId) {
      return res.status(403).json({ error: "This is not your assigned order" });
    }

    const updated = await prisma.order.update({
      where: { id },
      data: {
        status: "DELIVERED",
        paymentStatus: order.paymentMethod === "CASH" ? "PAID" : order.paymentStatus,
      },
      include: {
        items: true,
        patient: { select: { id: true, fullName: true, phone: true } },
        pharmacy: { select: { id: true, name: true, phone: true, address: true } },
      },
    });

    console.log(`✅ Order ${order.orderNumber} marked as DELIVERED by ${req.user.fullName}`);
    res.json({ message: "Order delivered successfully!", order: updated });
  } catch (error) {
    console.error("Deliver Order Error:", error);
    res.status(500).json({ error: "Failed to mark as delivered" });
  }
});

// ── POST /api/agent/orders/:id/report-delay ──────────────────────────────
// Agent reports a delay with a reason
router.post("/orders/:id/report-delay", authenticateToken, requireRoles("DELIVERY_AGENT"), async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    if (!reason) return res.status(400).json({ error: "Delay reason is required" });

    const order = await prisma.order.findUnique({
      where: { id },
      include: { pharmacy: true, patient: true },
    });
    if (!order) return res.status(404).json({ error: "Order not found" });

    // Store delay as an audit log entry
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userEmail: req.user.email,
        userRole: req.user.role,
        action: "DELIVERY_DELAY_REPORTED",
        tableName: "Order",
        recordId: id,
        newValue: JSON.stringify({
          reason,
          orderNumber: order.orderNumber,
          clientName: order.patient.fullName,
          pharmacyName: order.pharmacy.name,
          reportedAt: new Date().toISOString(),
        }),
        isSuspicious: false,
      },
    });

    console.log(`⚠️ Delay reported on order ${order.orderNumber}: ${reason}`);
    res.json({ message: "Delay reported successfully", reason });
  } catch (error) {
    console.error("Report Delay Error:", error);
    res.status(500).json({ error: "Failed to report delay" });
  }
});

// ── POST /api/agent/orders/:id/messages ──────────────────────────────────
// Send a chat message between agent and client for a specific order
router.post("/orders/:id/messages", authenticateToken, requireRoles("DELIVERY_AGENT", "PATIENT"), async (req, res) => {
  try {
    const { id: orderId } = req.params;
    const { content } = req.body;
    const senderId = req.user.id;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: "Message content is required" });
    }

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { patient: true },
    });
    if (!order) return res.status(404).json({ error: "Order not found" });

    // Determine receiver: if sender is agent → receiver is client, and vice versa
    let receiverId;
    if (req.user.role === "DELIVERY_AGENT") {
      receiverId = order.patientId;
    } else {
      receiverId = order.deliveryAgentId;
      if (!receiverId) return res.status(400).json({ error: "No delivery agent assigned to this order yet" });
    }

    const message = await prisma.message.create({
      data: {
        senderId,
        receiverId,
        orderId,
        content: content.trim(),
      },
      include: {
        sender: { select: { id: true, fullName: true, role: true } },
        receiver: { select: { id: true, fullName: true, role: true } },
      },
    });

    res.status(201).json({ message: "Message sent", data: message });
  } catch (error) {
    console.error("Send Message Error:", error);
    res.status(500).json({ error: "Failed to send message" });
  }
});

// ── GET /api/agent/orders/:id/messages ───────────────────────────────────
// Get chat messages for a specific order (both client and agent)
router.get("/orders/:id/messages", authenticateToken, async (req, res) => {
  try {
    const { id: orderId } = req.params;
    const userId = req.user.id;

    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order) return res.status(404).json({ error: "Order not found" });

    // Only patient or assigned delivery agent can read messages
    if (order.patientId !== userId && order.deliveryAgentId !== userId && req.user.role !== "PLATFORM_ADMIN") {
      return res.status(403).json({ error: "Not authorized to view messages for this order" });
    }

    const messages = await prisma.message.findMany({
      where: { orderId },
      include: {
        sender: { select: { id: true, fullName: true, role: true } },
      },
      orderBy: { createdAt: "asc" },
    });

    // Mark unread messages as read
    await prisma.message.updateMany({
      where: {
        orderId,
        receiverId: userId,
        read: false,
      },
      data: { read: true },
    });

    res.json({ count: messages.length, messages });
  } catch (error) {
    console.error("Fetch Messages Error:", error);
    res.status(500).json({ error: "Failed to fetch messages" });
  }
});

// ── POST /api/agent/orders/:id/report-problem ─────────────────────────────
// Client reports a problem with delivery (shown to Pharmacy Admin + Platform Admin)
router.post("/orders/:id/report-problem", authenticateToken, requireRoles("PATIENT"), async (req, res) => {
  try {
    const { id: orderId } = req.params;
    const { reason } = req.body;

    if (!reason) return res.status(400).json({ error: "Problem reason is required" });

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { pharmacy: true, deliveryAgent: true },
    });
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.patientId !== req.user.id) {
      return res.status(403).json({ error: "Not your order" });
    }

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userEmail: req.user.email,
        userRole: req.user.role,
        action: "CLIENT_REPORTED_DELIVERY_PROBLEM",
        tableName: "Order",
        recordId: orderId,
        newValue: JSON.stringify({
          reason,
          orderNumber: order.orderNumber,
          pharmacyName: order.pharmacy?.name,
          agentName: order.deliveryAgent?.fullName,
          reportedAt: new Date().toISOString(),
        }),
        isSuspicious: true, // flag it for admin attention
      },
    });

    console.log(`🚨 Problem reported on order ${order.orderNumber} by client: ${reason}`);
    res.json({ message: "Problem reported. Our support team has been notified.", reason });
  } catch (error) {
    console.error("Report Problem Error:", error);
    res.status(500).json({ error: "Failed to report problem" });
  }
});

// ── GET /api/agent/stats ──────────────────────────────────────────────────
// Get agent's daily earnings and delivery stats
router.get("/stats", authenticateToken, requireRoles("DELIVERY_AGENT"), async (req, res) => {
  try {
    const agentId = req.user.id;
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const deliveredToday = await prisma.order.findMany({
      where: {
        deliveryAgentId: agentId,
        status: "DELIVERED",
        updatedAt: { gte: todayStart },
      },
      select: {
        id: true,
        totalAmount: true,
        paymentMethod: true,
        paymentStatus: true,
        orderNumber: true,
      },
    });

    const totalDeliveries = deliveredToday.length;
    // Delivery fee: 500 FCFA per delivery (platform standard)
    const deliveryFeePerOrder = 500;
    const totalEarnings = totalDeliveries * deliveryFeePerOrder;
    // Cash in hand = total amount of CASH orders that were delivered
    const cashInHand = deliveredToday
      .filter(o => o.paymentMethod === "CASH")
      .reduce((sum, o) => sum + o.totalAmount, 0);

    res.json({
      deliveriesToday: totalDeliveries,
      earningsToday: totalEarnings,
      cashInHand,
      currency: "FCFA",
    });
  } catch (error) {
    console.error("Agent Stats Error:", error);
    res.status(500).json({ error: "Failed to fetch stats" });
  }
});

// ── PATCH /api/agent/availability ─────────────────────────────────────────
// Toggle agent online/offline status (stored in AuditLog for now, 
// since User model doesn't have availability field — we use a simple approach)
router.patch("/availability", authenticateToken, requireRoles("DELIVERY_AGENT"), async (req, res) => {
  try {
    const { isOnline } = req.body;
    if (typeof isOnline !== "boolean") {
      return res.status(400).json({ error: "isOnline must be a boolean" });
    }

    // Log availability change
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userEmail: req.user.email,
        userRole: req.user.role,
        action: isOnline ? "AGENT_WENT_ONLINE" : "AGENT_WENT_OFFLINE",
        tableName: "User",
        recordId: req.user.id,
        newValue: JSON.stringify({ isOnline, timestamp: new Date().toISOString() }),
        isSuspicious: false,
      },
    });

    console.log(`🟢 Agent ${req.user.fullName} is now ${isOnline ? "ONLINE" : "OFFLINE"}`);
    res.json({
      message: `You are now ${isOnline ? "online and ready for deliveries" : "offline"}`,
      isOnline,
    });
  } catch (error) {
    console.error("Availability Error:", error);
    res.status(500).json({ error: "Failed to update availability" });
  }
});

export default router;
