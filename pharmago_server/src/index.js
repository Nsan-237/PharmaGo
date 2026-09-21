import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

import authRoutes from "./routes/authRoutes.js";
import pharmacyRoutes from "./routes/pharmacyRoutes.js";
import productRoutes from "./routes/productRoutes.js";
import prescriptionRoutes from "./routes/prescriptionRoutes.js";
import orderRoutes from "./routes/orderRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
import paymentRoutes from "./routes/paymentRoutes.js";
import trackingRoutes from "./routes/trackingRoutes.js";
import deliveryRoutes from "./routes/deliveryRoutes.js";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5000;

// Ensure upload directory exists
const uploadDir = path.join(__dirname, "../public/uploads/prescriptions");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static(path.join(__dirname, "../public/uploads")));

// API Health Check
app.get("/api/health", (req, res) => {
  res.json({
    status: "online",
    service: "PharmaGo Backend API",
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use("/api/auth", authRoutes);
app.use("/api/pharmacies", pharmacyRoutes);
app.use("/api/products", productRoutes);
app.use("/api/prescriptions", prescriptionRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/payment", paymentRoutes);
app.use("/api/tracking", trackingRoutes);
app.use("/api/agent", deliveryRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: "API Route not found" });
});

// Start Server
app.listen(PORT, () => {
  console.log(`🚀 PharmaGo Backend API Server running on http://localhost:${PORT}`);
  console.log(`📡 Health Check: http://localhost:${PORT}/api/health`);
});
