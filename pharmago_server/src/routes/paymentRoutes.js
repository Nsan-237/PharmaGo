import express from "express";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();

const CAMPAY_APP_USERNAME = process.env.CAMPAY_APP_USERNAME || "";
const CAMPAY_APP_PASSWORD = process.env.CAMPAY_APP_PASSWORD || "";
const CAMPAY_ENV = process.env.CAMPAY_ENV || "demo"; // 'demo' or 'live'

// Get Campay Access Token
async function getCampayToken() {
  if (!CAMPAY_APP_USERNAME || !CAMPAY_APP_PASSWORD) {
    return null;
  }

  const baseUrl = CAMPAY_ENV === "live" ? "https://www.campay.net/api" : "https://demo.campay.net/api";

  try {
    const response = await fetch(`${baseUrl}/token/`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: CAMPAY_APP_USERNAME,
        password: CAMPAY_APP_PASSWORD,
      }),
    });

    const data = await response.json();
    return data.token || null;
  } catch (error) {
    console.error("Campay Auth Error:", error.message);
    return null;
  }
}

// Initiate Payment via Official Campay API (MTN MoMo & Orange Money Cameroon)
router.post("/initiate", authenticateToken, async (req, res) => {
  try {
    const { orderId, amount, phone, provider } = req.body;

    if (!orderId || !amount || !phone) {
      return res.status(400).json({ error: "orderId, amount, and phone number are required" });
    }

    // Format phone number to 237 standard
    let formattedPhone = phone.replace(/\D/g, "");
    if (!formattedPhone.startsWith("237") && formattedPhone.length === 9) {
      formattedPhone = "237" + formattedPhone;
    }

    const token = await getCampayToken();

    // If live Campay API keys exist, make real API request to Campay
    if (token) {
      const baseUrl = CAMPAY_ENV === "live" ? "https://www.campay.net/api" : "https://demo.campay.net/api";

      const campayRes = await fetch(`${baseUrl}/collect/`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Token ${token}`,
        },
        body: JSON.stringify({
          amount: String(amount),
          currency: "XAF",
          from: formattedPhone,
          description: `PharmaGo Order #${orderId}`,
          external_reference: String(orderId),
        }),
      });

      const campayData = await campayRes.json();

      return res.json({
        gateway: "CAMPAY_LIVE",
        status: "PENDING",
        reference: campayData.reference,
        ussd_code: campayData.ussd_code,
        operator: campayData.operator,
        message: `Mobile Money USSD prompt sent to ${formattedPhone}. Please enter your secret PIN.`,
      });
    }

    // Default Sandbox / Demonstration Payment Flow
    const transactionId = `TX-${provider || "MOMO"}-${Date.now()}`;
    res.json({
      gateway: "CAMPAY_SANDBOX",
      status: "SUCCESS",
      message: `[Sandbox] USSD payment prompt sent to ${formattedPhone} for ${amount} FCFA (${provider || "MTN MoMo"}).`,
      transactionId,
      orderId,
      amount,
      phone: formattedPhone,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("Campay Payment Exception:", error);
    res.status(500).json({ error: "Failed to process Campay mobile money transaction" });
  }
});

// Check Campay Transaction Status
router.get("/status/:reference", authenticateToken, async (req, res) => {
  const { reference } = req.params;
  const token = await getCampayToken();

  if (token) {
    const baseUrl = CAMPAY_ENV === "live" ? "https://www.campay.net/api" : "https://demo.campay.net/api";

    try {
      const statusRes = await fetch(`${baseUrl}/transaction/${reference}/`, {
        headers: { Authorization: `Token ${token}` },
      });
      const data = await statusRes.json();
      return res.json({ gateway: "CAMPAY_LIVE", ...data });
    } catch (err) {
      console.error("Campay Transaction Status Error:", err);
    }
  }

  res.json({
    gateway: "CAMPAY_SANDBOX",
    reference,
    status: "SUCCESSFUL",
    amount: "2500",
    currency: "XAF",
    paidAt: new Date().toISOString(),
  });
});

export default router;
