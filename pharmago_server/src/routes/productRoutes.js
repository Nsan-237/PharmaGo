import express from "express";
import prisma from "../db/prisma.js";
import { authenticateToken, requireRoles } from "../middleware/auth.js";

const router = express.Router();

// Search products globally across pharmacies
router.get("/search", async (req, res) => {
  try {
    const { q, category, requiresPrescription, limit = 30 } = req.query;

    const where = {};
    if (q) {
      where.OR = [
        { name: { contains: q } },
        { category: { contains: q } },
        { description: { contains: q } },
      ];
    }
    if (category) where.category = category;
    if (requiresPrescription === "true") where.requiresPrescription = true;
    if (requiresPrescription === "false") where.requiresPrescription = false;

    const products = await prisma.product.findMany({
      where,
      include: {
        pharmacy: {
          select: {
            id: true,
            name: true,
            city: true,
            quarter: true,
            isGuard247: true,
            latitude: true,
            longitude: true,
          },
        },
      },
      take: parseInt(limit),
    });

    res.json({ count: products.length, products });
  } catch (error) {
    console.error("Search Products Error:", error);
    res.status(500).json({ error: "Failed to search products" });
  }
});

// Add Product to Pharmacy Stock (Pharmacy Admin or Cashier)
router.post("/", authenticateToken, requireRoles("PHARMACY_ADMIN", "CASHIER", "PLATFORM_ADMIN"), async (req, res) => {
  try {
    const { pharmacyId, name, category, dosage, description, price, stockQuantity, requiresPrescription, batchNumber, expiryDate } = req.body;

    if (!pharmacyId || !name || !price || stockQuantity === undefined) {
      return res.status(400).json({ error: "pharmacyId, name, price and stockQuantity are required" });
    }

    const product = await prisma.product.create({
      data: {
        pharmacyId,
        name,
        category: category || "Général",
        dosage,
        description,
        price: parseFloat(price),
        stockQuantity: parseInt(stockQuantity),
        requiresPrescription: requiresPrescription === true || requiresPrescription === "true",
        batchNumber,
        expiryDate: expiryDate ? new Date(expiryDate) : null,
      },
    });

    res.status(201).json({ message: "Product added to stock", product });
  } catch (error) {
    console.error("Add Product Error:", error);
    res.status(500).json({ error: "Failed to add product" });
  }
});

// Update Product Stock or Details
router.put("/:id", authenticateToken, requireRoles("PHARMACY_ADMIN", "CASHIER", "PLATFORM_ADMIN"), async (req, res) => {
  try {
    const { id } = req.params;
    const { name, category, dosage, description, price, stockQuantity, requiresPrescription, batchNumber } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (category !== undefined) updateData.category = category;
    if (dosage !== undefined) updateData.dosage = dosage;
    if (description !== undefined) updateData.description = description;
    if (price !== undefined) updateData.price = parseFloat(price);
    if (stockQuantity !== undefined) updateData.stockQuantity = parseInt(stockQuantity);
    if (requiresPrescription !== undefined) updateData.requiresPrescription = requiresPrescription === true || requiresPrescription === "true";
    if (batchNumber !== undefined) updateData.batchNumber = batchNumber;

    const product = await prisma.product.update({
      where: { id },
      data: updateData,
    });

    res.json({ message: "Product updated", product });
  } catch (error) {
    console.error("Update Product Error:", error);
    res.status(500).json({ error: "Failed to update product" });
  }
});

// Delete Product from Stock
router.delete("/:id", authenticateToken, requireRoles("PHARMACY_ADMIN", "PLATFORM_ADMIN"), async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.product.delete({ where: { id } });
    res.json({ message: "Product deleted from inventory" });
  } catch (error) {
    console.error("Delete Product Error:", error);
    res.status(500).json({ error: "Failed to delete product" });
  }
});

export default router;
