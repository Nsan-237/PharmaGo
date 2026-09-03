import express from "express";
import prisma from "../db/prisma.js";
import { authenticateToken, requireRoles } from "../middleware/auth.js";

const router = express.Router();

// Helper: Haversine distance in kilometers
function getDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Get all pharmacies or filter by city, search query, or GPS proximity
router.get("/", async (req, res) => {
  try {
    const { city, search, lat, lng, isGuard, limit = 20 } = req.query;

    const where = { isApproved: true };
    if (city) where.city = { contains: city };
    if (isGuard === "true") where.isGuard247 = true;
    if (search) {
      where.OR = [
        { name: { contains: search } },
        { address: { contains: search } },
        { quarter: { contains: search } },
      ];
    }

    let pharmacies = await prisma.pharmacy.findMany({
      where,
      include: {
        _count: {
          select: { products: true },
        },
      },
      take: parseInt(limit),
    });

    // If user provided latitude and longitude, calculate distance & sort by proximity
    if (lat && lng) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);

      pharmacies = pharmacies
        .map((p) => {
          const distanceKm = getDistanceKm(userLat, userLng, p.latitude, p.longitude);
          return {
            ...p,
            distanceKm: parseFloat(distanceKm.toFixed(2)),
          };
        })
        .sort((a, b) => a.distanceKm - b.distanceKm);
    }

    res.json({ count: pharmacies.length, pharmacies });
  } catch (error) {
    console.error("Fetch Pharmacies Error:", error);
    res.status(500).json({ error: "Failed to fetch pharmacies" });
  }
});

// Get Pharmacy Details & Inventory by ID or Slug
router.get("/:idOrSlug", async (req, res) => {
  try {
    const { idOrSlug } = req.params;

    const pharmacy = await prisma.pharmacy.findFirst({
      where: {
        OR: [{ id: idOrSlug }, { slug: idOrSlug }],
      },
      include: {
        products: true,
      },
    });

    if (!pharmacy) {
      return res.status(404).json({ error: "Pharmacy not found" });
    }

    res.json({ pharmacy });
  } catch (error) {
    console.error("Pharmacy Detail Error:", error);
    res.status(500).json({ error: "Failed to fetch pharmacy details" });
  }
});

// Create new Pharmacy (Pending Approval)
router.post("/", authenticateToken, async (req, res) => {
  try {
    const { name, address, city, quarter, latitude, longitude, phone, email, licenseNo, isGuard247 } = req.body;

    if (!name || !address || !latitude || !longitude || !phone) {
      return res.status(400).json({ error: "Name, address, phone, and GPS coordinates are required" });
    }

    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, "-") + "-" + Date.now();

    const pharmacy = await prisma.pharmacy.create({
      data: {
        name,
        slug,
        address,
        city: city || "Douala",
        quarter,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        phone,
        email,
        licenseNo,
        isGuard247: isGuard247 === true || isGuard247 === "true",
        isApproved: req.user.role === "PLATFORM_ADMIN", // Auto approve if superadmin created
      },
    });

    // Link user as pharmacy admin
    await prisma.pharmacyStaff.create({
      data: {
        pharmacyId: pharmacy.id,
        userId: req.user.id,
        role: "PHARMACY_ADMIN",
      },
    });

    res.status(201).json({ message: "Pharmacy created successfully", pharmacy });
  } catch (error) {
    console.error("Create Pharmacy Error:", error);
    res.status(500).json({ error: "Failed to create pharmacy" });
  }
});

export default router;
