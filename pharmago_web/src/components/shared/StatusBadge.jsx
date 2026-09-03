import React from "react";
import { useT } from "../../i18n/TranslationContext";

const statusColors = {
  en_stock:     { bg: "#dcfce7", color: "#16a34a" },
  stock_faible: { bg: "#fef3c7", color: "#d97706" },
  rupture:      { bg: "#fee2e2", color: "#dc2626" },
  en_attente:   { bg: "#FEF3DC", color: "#E8A33D" },
  confirme:     { bg: "#dcfce7", color: "#16a34a" },
  en_route:     { bg: "#dbeafe", color: "#2563eb" },
  livree:       { bg: "#dcfce7", color: "#16a34a" },
  rejete:       { bg: "#fee2e2", color: "#dc2626" },
  actif:        { bg: "#dcfce7", color: "#16a34a" },
  suspendu:     { bg: "#fee2e2", color: "#dc2626" },
  disponible:   { bg: "#dcfce7", color: "#16a34a" },
  en_livraison: { bg: "#dbeafe", color: "#2563eb" },
  hors_ligne:   { bg: "#f3f4f6", color: "#6b7280" },
  ouvert:       { bg: "#fee2e2", color: "#dc2626" },
  en_cours:     { bg: "#FEF3DC", color: "#E8A33D" },
  resolu:       { bg: "#dcfce7", color: "#16a34a" },
  verifie:      { bg: "#dcfce7", color: "#16a34a" },
  assignee:     { bg: "#FEF3DC", color: "#E8A33D" },
  active:       { bg: "#dcfce7", color: "#16a34a" },
  suspended:    { bg: "#fee2e2", color: "#dc2626" },
};

export default function StatusBadge({ status, custom }) {
  const t = useT();
  const cfg = statusColors[status] || { bg: "#f3f4f6", color: "#6b7280" };
  const label = custom || t(`status.${status}`) || status;

  return (
    <span
      className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold"
      style={{ background: cfg.bg, color: cfg.color }}
    >
      {label}
    </span>
  );
}
