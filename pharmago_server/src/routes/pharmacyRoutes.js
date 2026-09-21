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

// ── POST /api/pharmacies (Platform Admin create pharmacy) ─────────────────
router.post("/", authenticateToken, requireRoles("PLATFORM_ADMIN"), async (req, res) => {
  try {
    const {
      name,
      address,
      city = "Douala",
      quarter,
      phone,
      email,
      openingHours = "08:00 - 20:00",
      isGuard247 = false,
      latitude = 4.0511,
      longitude = 9.7679,
      isApproved = true,
      licenseNo,
    } = req.body;

    if (!name || !address || !phone) {
      return res.status(400).json({ error: "Name, address, and phone are required" });
    }

    // Generate unique slug
    let baseSlug = name
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
    let slug = baseSlug;
    let counter = 1;
    while (await prisma.pharmacy.findUnique({ where: { slug } })) {
      slug = `${baseSlug}-${counter++}`;
    }

    const pharmacy = await prisma.pharmacy.create({
      data: {
        name: name.trim(),
        slug,
        address: address.trim(),
        city: city.trim(),
        quarter: quarter ? quarter.trim() : null,
        phone: phone.trim(),
        email: email ? email.trim() : null,
        openingHours,
        isGuard247: Boolean(isGuard247),
        isApproved: Boolean(isApproved),
        latitude: parseFloat(latitude) || 4.0511,
        longitude: parseFloat(longitude) || 9.7679,
        licenseNo: licenseNo ? licenseNo.trim() : null,
      },
    });

    await auditLog(req, {
      action: "CREATE_PHARMACY",
      tableName: "Pharmacy",
      recordId: pharmacy.id,
      newValue: { name: pharmacy.name, city: pharmacy.city },
    });

    res.status(201).json({ message: "Pharmacy created successfully", pharmacy });
  } catch (error) {
    console.error("Create pharmacy error:", error);
    res.status(500).json({ error: "Failed to create pharmacy" });
  }
});

// ── PUT /api/pharmacies/:id (Pharmacy Admin or Platform Admin) ────────────
router.put("/:id", authenticateToken, requireRoles("PHARMACY_ADMIN", "PLATFORM_ADMIN"), async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      address,
      city,
      quarter,
      openingHours,
      isGuard247,
      phone,
      email,
      isApproved,
      latitude,
      longitude,
    } = req.body;

    const old = await prisma.pharmacy.findUnique({ where: { id } });
    if (!old) return res.status(404).json({ error: "Pharmacy not found" });

    const updateData = {};
    if (name !== undefined) updateData.name = name.trim();
    if (address !== undefined) updateData.address = address.trim();
    if (city !== undefined) updateData.city = city.trim();
    if (quarter !== undefined) updateData.quarter = quarter ? quarter.trim() : null;
    if (openingHours !== undefined) updateData.openingHours = openingHours;
    if (isGuard247 !== undefined) updateData.isGuard247 = Boolean(isGuard247);
    if (phone !== undefined) updateData.phone = phone.trim();
    if (email !== undefined) updateData.email = email ? email.trim() : null;
    if (isApproved !== undefined) updateData.isApproved = Boolean(isApproved);
    if (latitude !== undefined) updateData.latitude = parseFloat(latitude);
    if (longitude !== undefined) updateData.longitude = parseFloat(longitude);

    const updated = await prisma.pharmacy.update({
      where: { id },
      data: updateData,
    });

    await auditLog(req, {
      action: "UPDATE_PHARMACY",
      tableName: "Pharmacy",
      recordId: id,
      oldValue: old,
      newValue: updated,
    });

    res.json({ message: "Pharmacy updated successfully", pharmacy: updated });
  } catch (error) {
    console.error("Update pharmacy error:", error);
    res.status(500).json({ error: "Failed to update pharmacy" });
  }
});

// ── DELETE /api/pharmacies/:id (Platform Admin only) ──────────────────────
router.delete("/:id", authenticateToken, requireRoles("PLATFORM_ADMIN"), async (req, res) => {
  try {
    const { id } = req.params;

    const pharmacy = await prisma.pharmacy.findUnique({ where: { id } });
    if (!pharmacy) return res.status(404).json({ error: "Pharmacy not found" });

    // Clean up relations
    await prisma.pharmacyStaff.deleteMany({ where: { pharmacyId: id } });
    await prisma.product.deleteMany({ where: { pharmacyId: id } });
    await prisma.pharmacy.delete({ where: { id } });

    await auditLog(req, {
      action: "DELETE_PHARMACY",
      tableName: "Pharmacy",
      recordId: id,
      oldValue: { name: pharmacy.name, city: pharmacy.city },
    });

    res.json({ message: "Pharmacy deleted successfully" });
  } catch (error) {
    console.error("Delete pharmacy error:", error);
    res.status(500).json({ error: "Failed to delete pharmacy" });
  }
});

export default router;
