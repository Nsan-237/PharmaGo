/**
 * PharmaGo — Time & Format Utilities
 * Provides relative timestamps, FCFA formatting, and date helpers
 */

/**
 * Returns a human-readable relative timestamp
 * e.g. "2 min ago", "il y a 2 min", "Just now", "Yesterday"
 * @param {string|Date} dateInput - ISO string or Date object
 * @param {string} lang - "fr" | "en"
 * @returns {string}
 */
export function timeAgo(dateInput, lang = "fr") {
  const date = dateInput instanceof Date ? dateInput : new Date(dateInput);
  const now = new Date();
  const diffMs = now - date;
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHr  = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHr  / 24);

  const isFr = lang === "fr";

  if (diffSec < 60)  return isFr ? "À l'instant"           : "Just now";
  if (diffMin < 60)  return isFr ? `il y a ${diffMin} min` : `${diffMin} min ago`;
  if (diffHr  < 24)  return isFr ? `il y a ${diffHr}h`     : `${diffHr}h ago`;
  if (diffDay === 1) return isFr ? "Hier"                   : "Yesterday";
  if (diffDay < 7)   return isFr ? `il y a ${diffDay}j`    : `${diffDay}d ago`;

  // Fall back to locale date string
  return date.toLocaleDateString(isFr ? "fr-CM" : "en-CM", {
    day: "2-digit",
    month: "short",
  });
}

/**
 * Formats a number in FCFA with thousands separator
 * @param {number} amount
 * @returns {string} e.g. "1 450 000 FCFA"
 */
export function formatFCFA(amount) {
  if (amount === null || amount === undefined) return "—";
  return `${Number(amount).toLocaleString("fr-CM")} FCFA`;
}

/**
 * Format an order date for display in a table
 * @param {string|Date} dateInput
 * @param {string} lang
 * @returns {string} e.g. "27 Août • 10h24"
 */
export function formatOrderDate(dateInput, lang = "fr") {
  const date = dateInput instanceof Date ? dateInput : new Date(dateInput);
  const isFr = lang === "fr";
  const datePart = date.toLocaleDateString(isFr ? "fr-CM" : "en-CM", {
    day: "2-digit",
    month: "short",
  });
  const timePart = date.toLocaleTimeString(isFr ? "fr-CM" : "en-CM", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  return `${datePart} • ${timePart}`;
}

/**
 * Returns initials from a full name
 * @param {string} fullName
 * @returns {string} e.g. "Marie Ngono" → "MN"
 */
export function getInitials(fullName = "") {
  return fullName
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}
