// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Auth Routes
// POST /api/auth/register  - Create new account (saves to DB)
// POST /api/auth/login     - Login with email/phone + password
// POST /api/auth/logout    - Invalidate token (client-side clear)
// GET  /api/auth/me        - Get current authenticated user
// ─────────────────────────────────────────────────────────────────────────────

import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import prisma from "../db/prisma.js";
import {
  authenticateToken,
  checkLoginRateLimit,
  recordLoginResult,
  auditLog,
} from "../middleware/auth.js";

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || "pharmago_secret_jwt_key_2026_cameroon";

// ── POST /api/auth/register ───────────────────────────────────────────────
router.post("/register", async (req, res) => {
  try {
    const { email, password, fullName, phone } = req.body;

    // Validate required fields
    if (!email || !password || !fullName) {
      return res.status(400).json({
        error: "Email, password and full name are required",
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: "Invalid email format" });
    }

    // Validate password strength (min 6 chars)
    if (password.length < 6) {
      return res.status(400).json({
        error: "Password must be at least 6 characters",
      });
    }

    // Check if email already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });
    if (existingUser) {
      return res.status(400).json({ error: "Email already registered" });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Create user in database (always PATIENT for self-registration)
    const user = await prisma.user.create({
      data: {
        email: email.toLowerCase(),
        passwordHash,
        fullName,
        phone: phone || null,
        role: "PATIENT",
        isApproved: true,
      },
    });

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: "30d" }
    );

    // Audit log the registration
    await auditLog(req, {
      action: "USER_REGISTERED",
      tableName: "User",
      recordId: user.id,
      newValue: { email: user.email, fullName: user.fullName, role: user.role },
    });

    console.log(`✅ New user registered: ${user.email} (${user.role})`);

    res.status(201).json({
      message: "Registration successful",
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (error) {
    console.error("Register Error:", error);
    res.status(500).json({ error: "Server error during registration" });
  }
});

// ── POST /api/auth/login ──────────────────────────────────────────────────
router.post("/login", checkLoginRateLimit, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";

  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    // Find user by email (support phone login too)
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: email.toLowerCase() },
          { phone: email }, // allow login with phone number
        ],
      },
      include: {
        pharmacyStaff: {
          include: { pharmacy: true },
        },
      },
    });

    if (!user) {
      await recordLoginResult(email, ip, false, "User not found");
      return res.status(401).json({ error: "Invalid email or password" });
    }

    // Check password
    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
      await recordLoginResult(email, ip, false, "Wrong password");
      return res.status(401).json({ error: "Invalid email or password" });
    }

    // Check if account is approved
    if (!user.isApproved) {
      await recordLoginResult(email, ip, false, "Account not approved");
      return res.status(403).json({ error: "Your account is not yet approved" });
    }

    // Clear rate limit on successful login
    await recordLoginResult(email, ip, true);

    // Generate token
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: "30d" }
    );

    // Get pharmacy if staff member
    const pharmacy = user.pharmacyStaff.length > 0
      ? user.pharmacyStaff[0].pharmacy
      : null;

    // Audit log successful login
    await auditLog(req, {
      action: "USER_LOGIN",
      tableName: "User",
      recordId: user.id,
      newValue: { email: user.email, role: user.role },
    });

    console.log(`✅ Login: ${user.email} (${user.role})`);

    res.json({
      message: "Login successful",
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role,
        pharmacy: pharmacy
          ? { id: pharmacy.id, name: pharmacy.name, slug: pharmacy.slug, city: pharmacy.city }
          : null,
      },
    });
  } catch (error) {
    console.error("Login Error:", error);
    await recordLoginResult(req.body.email || "", ip, false, "Server error");
    res.status(500).json({ error: "Server error during login" });
  }
});

// ── POST /api/auth/logout ─────────────────────────────────────────────────
router.post("/logout", authenticateToken, async (req, res) => {
  // Audit log the logout
  await auditLog(req, {
    action: "USER_LOGOUT",
    tableName: "User",
    recordId: req.user.id,
    newValue: { email: req.user.email },
  });

  console.log(`👋 Logout: ${req.user.email}`);

  // Token is cleared client-side. Here we just acknowledge.
  res.json({ message: "Logged out successfully" });
});

// ── GET /api/auth/me ──────────────────────────────────────────────────────
router.get("/me", authenticateToken, async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: {
      id: true,
      email: true,
      fullName: true,
      phone: true,
      role: true,
      avatarUrl: true,
      createdAt: true,
      pharmacyStaff: {
        include: { pharmacy: true },
      },
    },
  });

  const pharmacy = user.pharmacyStaff.length > 0
    ? user.pharmacyStaff[0].pharmacy
    : null;

  res.json({
    user: {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      pharmacy: pharmacy || null,
    },
  });
});

export default router;
