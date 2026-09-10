import express from "express";

const router = express.Router();

// ── Campay Credentials from .env ──────────────────────────────────────────────
const CAMPAY_USERNAME = process.env.CAMPAY_APP_USERNAME || "";
const CAMPAY_PASSWORD = process.env.CAMPAY_APP_PASSWORD || "";
// Permanent token skips the /token/ round-trip
const CAMPAY_PERMANENT_TOKEN = process.env.CAMPAY_PERMANENT_TOKEN || "";
const CAMPAY_ENV = process.env.CAMPAY_ENV || "demo";
const BASE_URL =
  CAMPAY_ENV === "live"
    ? "https://www.campay.net/api"
    : "https://demo.campay.net/api";

// ── Helper: get auth token (permanent first, then username/password) ──────────
let _cachedToken = null;
let _tokenExpiry = null;

async function getCampayToken() {
  // Use permanent token if available (fastest, no extra round-trip)
  if (CAMPAY_PERMANENT_TOKEN) {
    console.log("[Campay] Using permanent access token.");
    return CAMPAY_PERMANENT_TOKEN;
  }

  // Fallback: authenticate with username + password
  if (!CAMPAY_USERNAME || !CAMPAY_PASSWORD) {
    console.error("[Campay] No credentials found in .env — cannot authenticate.");
    return null;
  }

  // Return cached token if still valid
  if (_cachedToken && _tokenExpiry && new Date() < _tokenExpiry) {
    return _cachedToken;
  }

  console.log("[Campay] Fetching new token via username/password...");
  try {
    const response = await fetch(`${BASE_URL}/token/`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: CAMPAY_USERNAME, password: CAMPAY_PASSWORD }),
    });
    const data = await response.json();
    if (data.token) {
      _cachedToken = data.token;
      _tokenExpiry = new Date(Date.now() + 55 * 60 * 1000); // 55 minutes
      console.log("[Campay] Token obtained successfully.");
      return _cachedToken;
    }
    console.error("[Campay] Token fetch failed:", data);
    return null;
  } catch (err) {
    console.error("[Campay] Auth network error:", err.message);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/payment/initiate
// Called by Flutter Web (avoids CORS by proxying through Node backend)
// Body: { phone, amountFcfa, description?, orderId? }
// ─────────────────────────────────────────────────────────────────────────────
router.post("/initiate", async (req, res) => {
  try {
    const { phone, amountFcfa, description, orderId } = req.body;

    if (!phone || !amountFcfa) {
      return res.status(400).json({
        success: false,
        error: "phone and amountFcfa are required.",
      });
    }

    // Normalize phone: strip non-digits, prepend 237 if needed
    let normalizedPhone = phone.replace(/\D/g, "");
    if (!normalizedPhone.startsWith("237") && normalizedPhone.length <= 9) {
      normalizedPhone = "237" + normalizedPhone;
    }

    console.log(`[Campay] Initiating collect: ${normalizedPhone} → ${amountFcfa} XAF`);
    console.log(`[Campay] Using base URL: ${BASE_URL}`);

    const token = await getCampayToken();
    if (!token) {
      return res.status(503).json({
        success: false,
        error: "Could not obtain Campay token. Check server .env credentials.",
      });
    }

    const payload = {
      amount: String(amountFcfa),
      from: normalizedPhone,
      description: description || `PharmaGo Order${orderId ? " #" + orderId : ""}`,
      ...(orderId ? { external_reference: String(orderId) } : {}),
    };

    console.log("[Campay] POST /collect/ payload:", JSON.stringify(payload));

    const campayRes = await fetch(`${BASE_URL}/collect/`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Token ${token}`,
      },
      body: JSON.stringify(payload),
    });

    const campayData = await campayRes.json();
    console.log(`[Campay] /collect/ response (${campayRes.status}):`, JSON.stringify(campayData));

    if (campayRes.status === 200 || campayRes.status === 201) {
      return res.json({
        success: true,
        reference: campayData.reference,
        status: campayData.status || "PENDING",
        operator: campayData.operator || "",
        ussd_code: campayData.ussd_code || "",
        message: campayData.message || `USSD push sent to ${normalizedPhone}`,
      });
    } else {
      return res.status(400).json({
        success: false,
        error: campayData.detail || campayData.message || "Campay collect request failed.",
        campayStatus: campayRes.status,
        campayResponse: campayData,
      });
    }
  } catch (err) {
    console.error("[Campay] /initiate exception:", err.message);
    return res.status(500).json({
      success: false,
      error: "Internal server error while calling Campay: " + err.message,
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/payment/status/:reference
// Poll Campay to check if USSD payment was confirmed by user
// ─────────────────────────────────────────────────────────────────────────────
router.get("/status/:reference", async (req, res) => {
  const { reference } = req.params;

  try {
    const token = await getCampayToken();
    if (!token) {
      return res.status(503).json({ success: false, error: "Could not obtain Campay token." });
    }

    const statusRes = await fetch(`${BASE_URL}/transaction/${reference}/`, {
      headers: { Authorization: `Token ${token}` },
    });
    const data = await statusRes.json();
    console.log(`[Campay] /transaction/${reference}/ response:`, JSON.stringify(data));

    return res.json({
      success: true,
      reference,
      status: data.status || "PENDING",
      operator: data.operator || "",
      amount: data.amount || "",
      currency: data.currency || "XAF",
      paidAt: data.paidAt || data.updated_at || null,
    });
  } catch (err) {
    console.error("[Campay] /status/ error:", err.message);
    return res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
