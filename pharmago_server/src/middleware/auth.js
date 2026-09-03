import jwt from "jsonwebtoken";
import prisma from "../db/prisma.js";

export const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "Access token required" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "pharmago_secret_jwt_key_2026_cameroon");
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
          select: {
            pharmacyId: true,
            role: true,
          },
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

export const requireRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: `Requires one of roles: ${roles.join(", ")}` });
    }
    next();
  };
};
