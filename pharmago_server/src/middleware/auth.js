// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Security Middleware
// - Rate limiting (login brute force protection)
// - Audit logging (every sensitive action)
// - JWT authentication
// - Role-based access control
// ─────────────────────────────────────────────────────────────────────────────

import jwt from "jsonwebtoken";
import prisma from "../db/prisma.js";

const JWT_SECRET = process.env.JWT_SECRET || "pharmago_secret_jwt_key_2026_cameroon";

// ── In-memory rate limiter (login attempts per IP) ────────────────────────
const loginAttempts = new Map(); // key: email, value: { count, lockedUntil }

const MAX_ATTEMPTS = 5;
const LOCK_DURATION_MS = 15 * 60 * 1000; // 15 minutes

export const checkLoginRateLimit = async (req, res, next) => {
  const email = req.body.email?.toLowerCase();
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";

  if (!email) return next();

  const now = Date.now();
  const record = loginAttempts.get(email) || { count: 0, lockedUntil: null };

  // Check if account is locked
  if (record.lockedUntil && now < record.lockedUntil) {
    const minutesLeft = Math.ceil((record.lockedUntil - now) / 60000);

    // Log this suspicious attempt
    await prisma.loginAttempt.create({
      data: {
        email,
        ipAddress: ip,
        success: false,
        failReason: `Account locked - ${minutesLeft} minutes remaining`,
      },
    });

    // Log to audit
    await prisma.auditLog.create({
      data: {
        action: "LOGIN_BLOCKED",
        tableName: "User",
        userEmail: email,
        ipAddress: ip,
        isSuspicious: true,
        newValue: JSON.stringify({ reason: "Too many failed attempts", minutesLeft }),
      },
    });

    return res.status(429).json({
      error: `Too many failed login attempts. Account locked for ${minutesLeft} more minute(s).`,
    });
  }

  // Attach tracker to request for post-login update
  req.loginTracker = { email, ip };
  next();
};

export const recordLoginResult = async (email, ip, success, failReason = null) => {
  const now = Date.now();
  const record = loginAttempts.get(email) || { count: 0, lockedUntil: null };

  if (success) {
    // Clear attempts on success
    loginAttempts.delete(email);
  } else {
    record.count += 1;
    if (record.count >= MAX_ATTEMPTS) {
      record.lockedUntil = now + LOCK_DURATION_MS;
      console.warn(`🔒 Account locked: ${email} after ${record.count} failed attempts`);
    }
    loginAttempts.set(email, record);
  }

  // Save to DB
  await prisma.loginAttempt.create({
    data: { email, ipAddress: ip, success, failReason },
  });
};

// ── JWT Authentication ─────────────────────────────────────────────────────
export const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "Access token required" });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        role: true,
        isApproved: true,
        pharmacyStaff: {
          select: { pharmacyId: true, role: true },
        },
      },
    });

    if (!user || !user.isApproved) {
      return res.status(403).json({ error: "Account disabled or not approved" });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(403).json({ error: "Invalid or expired token" });
  }
};

// ── Role-Based Access Control ──────────────────────────────────────────────
export const requireRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      // Log unauthorized access attempt
      auditLog(req, {
        action: "UNAUTHORIZED_ACCESS",
        tableName: "System",
        isSuspicious: true,
        newValue: JSON.stringify({
          attemptedRoute: req.originalUrl,
          userRole: req.user?.role,
          requiredRoles: roles,
        }),
      });

      return res.status(403).json({
        error: `Access denied. Requires one of: ${roles.join(", ")}`,
      });
    }
    next();
  };
};

// ── Audit Logger Helper ────────────────────────────────────────────────────
export const auditLog = async (req, { action, tableName, recordId, oldValue, newValue, isSuspicious = false }) => {
  try {
    const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
    const userAgent = req.headers["user-agent"] || "unknown";

    await prisma.auditLog.create({
      data: {
        userId: req.user?.id || null,
        userEmail: req.user?.email || null,
        userRole: req.user?.role || null,
        action,
        tableName,
        recordId: recordId || null,
        oldValue: oldValue ? JSON.stringify(oldValue) : null,
        newValue: newValue ? JSON.stringify(newValue) : null,
        ipAddress: ip,
        userAgent,
        isSuspicious,
      },
    });
  } catch (err) {
    console.error("Audit log error:", err.message);
  }
};
