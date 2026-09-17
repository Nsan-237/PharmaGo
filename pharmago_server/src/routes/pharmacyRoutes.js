// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Pharmacy Routes
// GET /api/pharmacies        - List all approved pharmacies
// GET /api/pharmacies/:id    - Get single pharmacy with products
// GET /api/pharmacies/:id/products - Get products for a pharmacy
// ─────────────────────────────────────────────────────────────────────────────

import express from "express";
import prisma from "../db/prisma.js";
import { authenticateToken, requireRoles, auditLog } from "../middleware/auth.js";

const router = express.Router();

// ── GET /api/pharmacies ───────────────────────────────────────────────────
// Public: any client can see pharmacies
router.get("/", async (req, res) => {
  try {
    const { city, guard, search } = req.query;

    const where = { isApproved: true };
    if (city) where.city = city;
    if (guard === "true") where.isGuard247 = true;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { city: { contains: search, mode: "insensitive" } },
        { quarter: { contains: search, mode: "insensitive" } },
      ];
    }

    const pharmacies = await prisma.pharmacy.findMany({
      where,
      include: {
        _count: { select: { products: true, orders: true } },
      },
      orderBy: { rating: "desc" },
    });

    res.json({ pharmacies, total: pharmacies.length });
  } catch (error) {
    console.error("Pharmacies error:", error);
    res.status(500).json({ error: "Failed to load pharmacies" });
  }
});

// ── GET /api/pharmacies/:id ───────────────────────────────────────────────
router.get("/:id", async (req, res) => {
  try {
    const pharmacy = await prisma.pharmacy.findUnique({
      where: { id: req.params.id },
      include: {
        products: {
          where: { stockQuantity: { gt: 0 } },
          orderBy: { name: "asc" },
        },
        _count: { select: { orders: true } },
      },
    });

    if (!pharmacy) {
      return res.status(404).json({ error: "Pharmacy not found" });
    }

    res.json({ pharmacy });
  } catch (error) {
    console.error("Pharmacy detail error:", error);
    res.status(500).json({ error: "Failed to load pharmacy" });
  }
});

// ── GET /api/pharmacies/:id/products ─────────────────────────────────────
router.get("/:id/products", async (req, res) => {
  try {
    const { category, search, inStock } = req.query;

    const where = { pharmacyId: req.params.id };
    if (category) where.category = category;
    if (inStock === "true") where.stockQuantity = { gt: 0 };
    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { category: { contains: search, mode: "insensitive" } },
      ];
    }

    const products = await prisma.product.findMany({
      where,
      orderBy: { name: "asc" },
    });

    res.json({ products, total: products.length });
  } catch (error) {
    console.error("Products error:", error);
    res.status(500).json({ error: "Failed to load products" });
  }
});

// ── PUT /api/pharmacies/:id (Pharmacy Admin only) ─────────────────────────
router.put("/:id", authenticateToken, requireRoles("PHARMACY_ADMIN", "PLATFORM_ADMIN"), async (req, res) => {
  try {
    const { id } = req.params;
    const { openingHours, isGuard247, phone, email } = req.body;

    const old = await prisma.pharmacy.findUnique({ where: { id } });

    const updated = await prisma.pharmacy.update({
      where: { id },
      data: { openingHours, isGuard247, phone, email },
    });

    await auditLog(req, {
      action: "UPDATE_PHARMACY",
      tableName: "Pharmacy",
      recordId: id,
      oldValue: old,
      newValue: updated,
    });

    res.json({ pharmacy: updated });
  } catch (error) {
    console.error("Update pharmacy error:", error);
    res.status(500).json({ error: "Failed to update pharmacy" });
  }
});

export default router;
