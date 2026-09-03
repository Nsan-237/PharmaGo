import express from "express";
import { authenticateToken, requireRoles } from "../middleware/auth.js";

const router = express.Router();

// In-memory driver location cache: orderId -> { lat, lng, timestamp, agentId }
const driverLocations = new Map();

// Delivery agent updates location coordinates
router.post("/location", authenticateToken, requireRoles("DELIVERY_AGENT", "PLATFORM_ADMIN"), (req, res) => {
  const { orderId, lat, lng } = req.body;

  if (!orderId || lat === undefined || lng === undefined) {
    return res.status(400).json({ error: "orderId, lat, and lng are required" });
  }

  const locationData = {
    orderId,
    agentId: req.user.id,
    agentName: req.user.fullName,
    lat: parseFloat(lat),
    lng: parseFloat(lng),
    timestamp: new Date().toISOString(),
  };

  driverLocations.set(orderId, locationData);

  res.json({ message: "Location updated", location: locationData });
});

// Patient or Pharmacy gets latest driver location for an order
router.get("/location/:orderId", authenticateToken, (req, res) => {
  const { orderId } = req.params;

  const location = driverLocations.get(orderId);
  if (!location) {
    // Default fallback coordinates near Douala Akwa
    return res.json({
      orderId,
      lat: 4.0511,
      lng: 9.7085,
      timestamp: new Date().toISOString(),
      isSimulated: true,
    });
  }

  res.json({ location });
});

export default router;
