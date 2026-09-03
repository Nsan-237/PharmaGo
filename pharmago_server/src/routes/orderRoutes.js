import express from "express";
import prisma from "../db/prisma.js";
import { authenticateToken, requireRoles } from "../middleware/auth.js";

const router = express.Router();

// Generate unique order number (e.g. PG-2026-X89A)
function generateOrderNumber() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let random = "";
  for (let i = 0; i < 4; i++) {
    random += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `PG-${new Date().getFullYear()}-${random}`;
}

// Patient creates an order
router.post("/", authenticateToken, async (req, res) => {
  try {
    const { pharmacyId, items, deliveryAddress, deliveryLat, deliveryLng, prescriptionId, paymentMethod } = req.body;

    if (!pharmacyId || !items || !Array.isArray(items) || items.length === 0 || !deliveryAddress) {
      return res.status(400).json({ error: "pharmacyId, items list, and deliveryAddress are required" });
    }

    let totalAmount = 0;
    const orderItemsData = [];

    for (const item of items) {
      const product = await prisma.product.findUnique({ where: { id: item.productId } });
      if (!product) {
        return res.status(400).json({ error: `Product ${item.productId} not found` });
      }
      if (product.stockQuantity < item.quantity) {
        return res.status(400).json({ error: `Insufficient stock for ${product.name}` });
      }

      const subtotal = product.price * item.quantity;
      totalAmount += subtotal;

      orderItemsData.push({
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: item.quantity,
        subtotal,
      });

      // Deduct stock quantity
      await prisma.product.update({
        where: { id: product.id },
        data: { stockQuantity: product.stockQuantity - item.quantity },
      });
    }

    const order = await prisma.order.create({
      data: {
        orderNumber: generateOrderNumber(),
        patientId: req.user.id,
        pharmacyId,
        prescriptionId: prescriptionId || null,
        status: "PENDING",
        totalAmount,
        deliveryAddress,
        deliveryLat: deliveryLat ? parseFloat(deliveryLat) : null,
        deliveryLng: deliveryLng ? parseFloat(deliveryLng) : null,
        paymentMethod: paymentMethod || "CASH",
        paymentStatus: paymentMethod === "CASH" ? "PENDING" : "PAID",
        items: {
          create: orderItemsData,
        },
      },
      include: {
        items: true,
        pharmacy: true,
      },
    });

    res.status(201).json({ message: "Order placed successfully", order });
  } catch (error) {
    console.error("Create Order Error:", error);
    res.status(500).json({ error: "Failed to place order" });
  }
});

// Get orders list based on user role (Patient, Pharmacy Admin, Cashier, Delivery Driver, Platform Admin)
router.get("/", authenticateToken, async (req, res) => {
  try {
    const { status, pharmacyId } = req.query;
    const { id: userId, role } = req.user;

    const where = {};
    if (status) where.status = status;

    // Scoping query per role
    if (role === "PATIENT") {
      where.patientId = userId;
    } else if (role === "DELIVERY_AGENT") {
      where.OR = [{ deliveryAgentId: userId }, { status: "READY_FOR_PICKUP" }];
    } else if (role === "PHARMACY_ADMIN" || role === "CASHIER") {
      const staffRecord = req.user.pharmacyStaff[0];
      if (staffRecord) {
        where.pharmacyId = staffRecord.pharmacyId;
      } else if (pharmacyId) {
        where.pharmacyId = pharmacyId;
      }
    }

    const orders = await prisma.order.findMany({
      where,
      include: {
        items: true,
        patient: { select: { id: true, fullName: true, phone: true } },
        pharmacy: { select: { id: true, name: true, phone: true, address: true } },
        deliveryAgent: { select: { id: true, fullName: true, phone: true } },
      },
      orderBy: { createdAt: "desc" },
    });

    res.json({ count: orders.length, orders });
  } catch (error) {
    console.error("Fetch Orders Error:", error);
    res.status(500).json({ error: "Failed to fetch orders" });
  }
});

// Update Order Status (Cashier, Pharmacy Admin, Delivery Agent)
router.put("/:id/status", authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, deliveryAgentId, paymentStatus } = req.body;

    const validStatuses = ["PENDING", "CONFIRMED", "PREPARING", "READY_FOR_PICKUP", "IN_TRANSIT", "DELIVERED", "CANCELLED"];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({ error: `Invalid status. Must be one of ${validStatuses.join(", ")}` });
    }

    const updateData = {};
    if (status) updateData.status = status;
    if (deliveryAgentId) updateData.deliveryAgentId = deliveryAgentId;
    if (paymentStatus) updateData.paymentStatus = paymentStatus;

    const order = await prisma.order.update({
      where: { id },
      data: updateData,
      include: {
        items: true,
        patient: true,
        deliveryAgent: true,
      },
    });

    res.json({ message: "Order status updated", order });
  } catch (error) {
    console.error("Update Order Error:", error);
    res.status(500).json({ error: "Failed to update order" });
  }
});

export default router;
