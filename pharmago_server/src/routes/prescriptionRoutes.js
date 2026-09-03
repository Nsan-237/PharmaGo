import express from "express";
import multer from "multer";
import path from "path";
import prisma from "../db/prisma.js";
import { authenticateToken, requireRoles } from "../middleware/auth.js";

const router = express.Router();

// File upload configuration for prescription photos
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "public/uploads/prescriptions/");
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, "rx-" + uniqueSuffix + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

// Patient uploads prescription photo
router.post("/upload", authenticateToken, upload.single("prescriptionImage"), async (req, res) => {
  try {
    const { pharmacyId, notes } = req.body;

    let imageUrl = req.file ? `/uploads/prescriptions/${req.file.filename}` : req.body.imageUrl;

    if (!imageUrl) {
      return res.status(400).json({ error: "Prescription image file or URL is required" });
    }

    const prescription = await prisma.prescription.create({
      data: {
        patientId: req.user.id,
        pharmacyId: pharmacyId || null,
        imageUrl,
        notes,
        status: "SUBMITTED",
      },
      include: {
        pharmacy: true,
      },
    });

    res.status(201).json({ message: "Prescription submitted for verification", prescription });
  } catch (error) {
    console.error("Prescription Upload Error:", error);
    res.status(500).json({ error: "Failed to upload prescription" });
  }
});

// Get prescriptions for Cashier verification queue
router.get("/queue", authenticateToken, requireRoles("CASHIER", "PHARMACY_ADMIN", "PLATFORM_ADMIN"), async (req, res) => {
  try {
    const { pharmacyId, status } = req.query;

    const where = {};
    if (pharmacyId) where.pharmacyId = pharmacyId;
    if (status) where.status = status;

    const prescriptions = await prisma.prescription.findMany({
      where,
      include: {
        patient: {
          select: { id: true, fullName: true, phone: true, email: true },
        },
        pharmacy: {
          select: { id: true, name: true },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    res.json({ count: prescriptions.length, prescriptions });
  } catch (error) {
    console.error("Prescription Queue Error:", error);
    res.status(500).json({ error: "Failed to fetch prescription queue" });
  }
});

// Cashier updates status and sets total price for prescription
router.put("/:id/verify", authenticateToken, requireRoles("CASHIER", "PHARMACY_ADMIN", "PLATFORM_ADMIN"), async (req, res) => {
  try {
    const { id } = req.params;
    const { status, pricedAmount, pharmacistNotes } = req.body;

    if (!status || !["VERIFIED", "PRICED", "REJECTED"].includes(status)) {
      return res.status(400).json({ error: "Valid status (VERIFIED, PRICED, REJECTED) is required" });
    }

    const prescription = await prisma.prescription.update({
      where: { id },
      data: {
        status,
        pricedAmount: pricedAmount ? parseFloat(pricedAmount) : undefined,
        pharmacistNotes,
      },
    });

    res.json({ message: "Prescription verification updated", prescription });
  } catch (error) {
    console.error("Verify Prescription Error:", error);
    res.status(500).json({ error: "Failed to verify prescription" });
  }
});

export default router;
