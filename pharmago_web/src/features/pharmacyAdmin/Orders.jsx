import React, { useState } from "react";
import {
  Download, FileText, CheckCircle, XCircle, Truck,
  PackageCheck, Clock, Eye, AlertTriangle, X
} from "lucide-react";
import { orders as initialOrders } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { useLang } from "../../i18n/TranslationContext";
import { exportToCSV, exportToPDF } from "../../utils/exportUtils";
import { apiUpdateOrderStatus } from "../../utils/api";
import { useToast } from "../../components/shared/Toast";
import StatusBadge from "../../components/shared/StatusBadge";
import { timeAgo, getInitials } from "../../utils/timeUtils";
import { PageHeader, Card, TableWrapper, Th, Td, Modal, SecondaryButton } from "../../components/shared/UI";

// Status progression flow:  en_attente → confirme → en_route → livree
// Can also be rejected at any point before livree

const ACTIONS = {
  en_attente:  ["confirme", "rejete"],
  confirme:    ["en_route", "rejete"],
  en_route:    ["livree"],
  livree:      [],
  rejete:      [],
};

const ACTION_META = {
  confirme:  { icon: CheckCircle, label: { fr: "Confirmer",       en: "Confirm"       }, color: "#16A34A", bg: "#DCFCE7" },
  en_route:  { icon: Truck,       label: { fr: "Mettre en route", en: "Mark en route" }, color: "#2563EB", bg: "#DBEAFE" },
  livree:    { icon: PackageCheck,label: { fr: "Marquer livrée",  en: "Mark delivered"}, color: "#0F9B8E", bg: "#E6F7F6" },
  rejete:    { icon: XCircle,     label: { fr: "Rejeter",         en: "Reject"        }, color: "#DC2626", bg: "#FEE2E2" },
};

const TABS = [
  { key: "all",        labelFr: "Toutes",         labelEn: "All" },
  { key: "en_attente", labelFr: "En attente",     labelEn: "Pending" },
  { key: "confirme",   labelFr: "Confirmées",     labelEn: "Confirmed" },
  { key: "en_route",   labelFr: "En route",       labelEn: "In transit" },
  { key: "livree",     labelFr: "Livrées",        labelEn: "Delivered" },
  { key: "rejete",     labelFr: "Rejetées",       labelEn: "Rejected" },
];

// Reject reason modal component
function RejectModal({ order, onConfirm, onClose, isFr }) {
  const [reason, setReason] = useState("");
  if (!order) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 animate-fade-in"
      style={{ background: "rgba(13,59,54,0.4)", backdropFilter: "blur(4px)" }}
      onClick={onClose}
    >
      <div
        className="bg-white rounded-2xl shadow-2xl w-full max-w-sm animate-fade-in-up"
        onClick={e => e.stopPropagation()}
      >
        <div className="p-5 border-b flex items-center justify-between" style={{ borderColor: "#DCE6E2" }}>
          <p className="font-bold font-sora" style={{ color: "#0D3B36" }}>
            {isFr ? "Rejeter la commande" : "Reject order"}
          </p>
          <button onClick={onClose} className="p-1 rounded text-gray-400 hover:text-gray-600">
            <X size={16} />
          </button>
        </div>
        <div className="p-5 space-y-4">
          <div className="flex items-center gap-2 p-3 rounded-lg" style={{ background: "#FEE2E2" }}>
            <AlertTriangle size={16} className="text-red-500 shrink-0" />
            <p className="text-sm text-red-700">
              {isFr ? `Commande ${order.id} — ${order.client}` : `Order ${order.id} — ${order.client}`}
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>
              {isFr ? "Motif du rejet (optionnel)" : "Rejection reason (optional)"}
            </label>
            <textarea
              value={reason}
              onChange={e => setReason(e.target.value)}
              rows={3}
              className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none resize-none focus:border-red-400 transition-all"
              style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }}
              placeholder={isFr ? "Ex: stock insuffisant, ordonnance manquante..." : "E.g. out of stock, missing prescription..."}
            />
          </div>
          <div className="flex gap-3">
            <SecondaryButton onClick={onClose} className="flex-1 justify-center">
              {isFr ? "Annuler" : "Cancel"}
            </SecondaryButton>
            <button
              onClick={() => onConfirm(reason)}
              className="flex-1 py-2.5 rounded-lg text-white font-semibold text-sm bg-red-500 hover:bg-red-600 transition-all active:scale-95"
            >
              {isFr ? "Confirmer le rejet" : "Confirm rejection"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function PharmaOrders() {
  const t = useT();
  const { lang } = useLang();
  const isFr = lang === "fr";
  const toast = useToast();

  const [orders, setOrders] = useState(initialOrders);
  const [filter, setFilter] = useState("all");
  const [rejectTarget, setRejectTarget] = useState(null);

  const filtered = filter === "all" ? orders : orders.filter(o => o.status === filter);

  // ── Status Action ──────────────────────────────────────────────────────────
  const applyStatus = async (id, newStatus, reason = "") => {
    try {
      await apiUpdateOrderStatus(id, { status: newStatus, reason });
    } catch (_) {}
    setOrders(prev => prev.map(o => o.id === id ? { ...o, status: newStatus } : o));

    const meta = ACTION_META[newStatus];
    const order = orders.find(o => o.id === id);
    if (newStatus === "rejete") {
      toast.warning(
        isFr ? `Commande ${id} rejetée.` : `Order ${id} rejected.`,
        isFr ? "Commande rejetée" : "Order rejected"
      );
    } else {
      toast.success(
        isFr
          ? `Commande ${id} — statut mis à jour : ${meta?.label.fr}.`
          : `Order ${id} — status updated: ${meta?.label.en}.`,
        isFr ? "Statut mis à jour" : "Status updated"
      );
    }
    setRejectTarget(null);
  };

  // ── Export ─────────────────────────────────────────────────────────────────
  const headers = [
    isFr ? "N° Commande" : "Order #",
    isFr ? "Client" : "Client",
    isFr ? "Médicaments" : "Medications",
    isFr ? "Total" : "Total",
    isFr ? "Type" : "Type",
    isFr ? "Statut" : "Status",
    isFr ? "Date" : "Date",
  ];
  const toRows = list => list.map(o => [
    o.id, o.client,
    o.drugs.map(d => `${d.name} ×${d.qty}`).join(", "),
    `${o.total.toLocaleString()} FCFA`,
    o.type === "livraison" ? (isFr ? "Livraison" : "Delivery") : (isFr ? "Retrait" : "Pickup"),
    o.status,
    new Date(o.createdAt).toLocaleDateString(isFr ? "fr-CM" : "en-CM"),
  ]);
  const handleCSV = () => exportToCSV(headers, toRows(filtered), `pharmago_orders_${new Date().toISOString().slice(0, 10)}`);
  const handlePDF = () => exportToPDF(isFr ? "Commandes" : "Orders", headers, toRows(filtered), `pharmago_orders_${new Date().toISOString().slice(0, 10)}`);

  return (
    <div className="animate-fade-in-up">
      <PageHeader
        title={isFr ? "Gestion des Commandes" : "Order Management"}
        subtitle={isFr ? `${orders.length} commandes au total` : `${orders.length} total orders`}
      />

      {/* Tab + Export bar */}
      <div className="flex items-center gap-2 mb-5 overflow-x-auto pb-1">
        <div className="flex gap-1.5 flex-1 flex-wrap">
          {TABS.map(tab => {
            const count = tab.key === "all" ? orders.length : orders.filter(o => o.status === tab.key).length;
            return (
              <button key={tab.key} onClick={() => setFilter(tab.key)}
                className={`px-3 py-1.5 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
                  filter === tab.key ? "text-white shadow-sm" : "bg-white text-gray-600 border hover:bg-gray-50"
                }`}
                style={filter === tab.key ? { background: "#0F9B8E" } : { borderColor: "#DCE6E2" }}
              >
                {isFr ? tab.labelFr : tab.labelEn}
                {count > 0 && <span className="ml-1.5 text-[11px] opacity-75">({count})</span>}
              </button>
            );
          })}
        </div>
        <button onClick={handleCSV}
          className="flex items-center gap-1.5 px-3 py-2 rounded-lg border text-sm font-medium hover:bg-gray-50 transition-colors shrink-0"
          style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}>
          <Download size={14} /> CSV
        </button>
        <button onClick={handlePDF}
          className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-white text-sm font-medium hover:opacity-90 transition-colors shrink-0"
          style={{ background: "#0F9B8E" }}>
          <FileText size={14} /> PDF
        </button>
      </div>

      <Card>
        {filtered.length === 0 ? (
          <div className="py-20 text-center">
            <Clock size={44} className="mx-auto text-gray-200 mb-3" />
            <p className="font-semibold text-gray-400">
              {isFr ? "Aucune commande dans cette catégorie" : "No orders in this category"}
            </p>
          </div>
        ) : (
          <TableWrapper>
            <thead>
              <tr>
                <Th>{isFr ? "N° Commande" : "Order #"}</Th>
                <Th>{isFr ? "Client" : "Client"}</Th>
                <Th>{isFr ? "Médicaments" : "Medications"}</Th>
                <Th>{isFr ? "Total" : "Total"}</Th>
                <Th>{isFr ? "Type" : "Type"}</Th>
                <Th>{isFr ? "Statut" : "Status"}</Th>
                <Th>{isFr ? "Date" : "Date"}</Th>
                <Th>{isFr ? "Actions" : "Actions"}</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((o, idx) => {
                const actions = ACTIONS[o.status] || [];
                return (
                  <tr key={o.id}
                    className="table-row-hover border-b animate-fade-in-up"
                    style={{ borderColor: "#F0F0F0", animationDelay: `${idx * 25}ms` }}
                  >
                    <Td>
                      <span className="font-mono font-semibold text-sm" style={{ color: "#0F9B8E" }}>{o.id}</span>
                    </Td>
                    <Td>
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0" style={{ background: "#0D3B36" }}>
                          {getInitials(o.client)}
                        </div>
                        <div>
                          <p className="font-medium text-sm" style={{ color: "#0D3B36" }}>{o.client}</p>
                          <p className="text-xs text-gray-400">{o.phone}</p>
                        </div>
                      </div>
                    </Td>
                    <Td>
                      <p className="text-xs text-gray-600 max-w-[160px] truncate">
                        {o.drugs.map(d => `${d.name} ×${d.qty}`).join(", ")}
                      </p>
                    </Td>
                    <Td>
                      <span className="font-bold text-sm">{o.total.toLocaleString()} <span className="text-xs font-normal text-gray-400">FCFA</span></span>
                    </Td>
                    <Td>
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${o.type === "livraison" ? "bg-blue-50 text-blue-700" : "bg-gray-100 text-gray-600"}`}>
                        {o.type === "livraison" ? (isFr ? "🚚 Livraison" : "🚚 Delivery") : (isFr ? "🏪 Retrait" : "🏪 Pickup")}
                      </span>
                    </Td>
                    <Td><StatusBadge status={o.status} /></Td>
                    <Td>
                      <p className="text-xs text-gray-400">{timeAgo(o.createdAt, lang)}</p>
                    </Td>
                    <Td>
                      {actions.length === 0 ? (
                        <span className="text-xs text-gray-300 italic">{isFr ? "Aucune action" : "No actions"}</span>
                      ) : (
                        <div className="flex items-center gap-1.5 flex-wrap">
                          {actions.map(act => {
                            const meta = ACTION_META[act];
                            const Icon = meta.icon;
                            return (
                              <button
                                key={act}
                                onClick={() => act === "rejete" ? setRejectTarget(o) : applyStatus(o.id, act)}
                                className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-all hover:opacity-90 active:scale-95"
                                style={{ background: meta.bg, color: meta.color }}
                                title={meta.label[lang] || meta.label.fr}
                              >
                                <Icon size={12} />
                                <span className="hidden lg:inline">{meta.label[lang] || meta.label.fr}</span>
                              </button>
                            );
                          })}
                        </div>
                      )}
                    </Td>
                  </tr>
                );
              })}
            </tbody>
          </TableWrapper>
        )}

        {filtered.length > 0 && (
          <div className="px-4 py-3 border-t flex items-center justify-between text-xs text-gray-400" style={{ borderColor: "#DCE6E2" }}>
            <span>{filtered.length} {isFr ? "commandes affichées" : "orders shown"}</span>
            <span className="font-semibold" style={{ color: "#0D3B36" }}>
              {isFr ? "Total" : "Total"}: {filtered.reduce((s, o) => s + o.total, 0).toLocaleString()} FCFA
            </span>
          </div>
        )}
      </Card>

      {/* Reject reason modal */}
      <RejectModal
        order={rejectTarget}
        onConfirm={reason => applyStatus(rejectTarget.id, "rejete", reason)}
        onClose={() => setRejectTarget(null)}
        isFr={isFr}
      />
    </div>
  );
}
