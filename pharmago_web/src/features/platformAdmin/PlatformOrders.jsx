import React, { useState, useMemo } from "react";
import {
  Search, Filter, Download, TrendingUp, ShoppingBag,
  Clock, CheckCircle, XCircle, Truck, RefreshCw, Eye, MapPin, FileText
} from "lucide-react";
import { orders, pharmacies } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { useLang } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";
import { timeAgo, formatFCFA, getInitials } from "../../utils/timeUtils";
import { exportToCSV } from "../../utils/exportUtils";

// Status icons map
const STATUS_META = {
  en_attente: { color: "#E8A33D", bg: "#FEF3DC", icon: Clock },
  confirme:   { color: "#2563EB", bg: "#DBEAFE", icon: CheckCircle },
  en_route:   { color: "#7C3AED", bg: "#EDE9FE", icon: Truck },
  livree:     { color: "#16A34A", bg: "#DCFCE7", icon: CheckCircle },
  rejete:     { color: "#DC2626", bg: "#FEE2E2", icon: XCircle },
};

const ALL_STATUSES = ["all", "en_attente", "confirme", "en_route", "livree", "rejete"];
const ALL_TYPES    = ["all", "livraison", "retrait"];

function OrderDetailModal({ order, onClose, t, lang }) {
  if (!order) return null;
  const isFr = lang === "fr";
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 animate-fade-in"
      style={{ background: "rgba(13,59,54,0.45)", backdropFilter: "blur(4px)" }}
      onClick={onClose}
    >
      <div
        className="bg-white rounded-2xl shadow-2xl w-full max-w-lg animate-fade-in-up"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          className="p-5 rounded-t-2xl flex items-center justify-between"
          style={{ background: "#0D3B36" }}
        >
          <div>
            <p className="font-mono font-bold text-lg text-white">{order.id}</p>
            <p className="text-xs text-white/60 mt-0.5">{timeAgo(order.createdAt, lang)}</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg text-white/60 hover:text-white hover:bg-white/10 transition-colors"
          >
            <XCircle size={20} />
          </button>
        </div>

        <div className="p-5 space-y-5">
          {/* Client */}
          <div className="flex items-center gap-3">
            <div
              className="w-11 h-11 rounded-full flex items-center justify-center text-white font-bold font-sora shrink-0"
              style={{ background: "#0F9B8E" }}
            >
              {getInitials(order.client)}
            </div>
            <div>
              <p className="font-semibold" style={{ color: "#0D3B36" }}>{order.client}</p>
              <p className="text-sm text-gray-400">{order.phone}</p>
              {order.address && (
                <p className="text-xs text-gray-400 flex items-center gap-1 mt-0.5">
                  <MapPin size={10} />  {order.address}
                </p>
              )}
            </div>
            <div className="ml-auto flex flex-col items-end gap-1">
              <StatusBadge status={order.status} />
              <span className={`text-[11px] px-2 py-0.5 rounded-full font-medium ${order.type === "livraison" ? "bg-blue-50 text-blue-700" : "bg-gray-100 text-gray-600"}`}>
                {order.type === "livraison" ? (isFr ? "Livraison" : "Delivery") : (isFr ? "Retrait" : "Pickup")}
              </span>
            </div>
          </div>

          {/* Drug list */}
          <div className="p-4 rounded-xl" style={{ background: "#F6F5EF" }}>
            <p className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-3 flex items-center gap-1.5">
              <ShoppingBag size={12} />  {isFr ? "Médicaments commandés" : "Medications ordered"}
            </p>
            <div className="space-y-2">
              {order.drugs.map((d, i) => (
                <div key={i} className="flex items-center justify-between">
                  <span className="text-sm font-medium" style={{ color: "#0D3B36" }}>{d.name}</span>
                  <span className="text-sm text-gray-500 font-semibold">×{d.qty}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Total + Rx badge */}
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-gray-400">{isFr ? "Total commande" : "Order total"}</p>
              <p className="text-2xl font-bold font-sora" style={{ color: "#0D3B36" }}>
                {order.total.toLocaleString()} <span className="text-base text-gray-400 font-normal">FCFA</span>
              </p>
            </div>
            {order.hasPrescription && (
              <span className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-purple-50 text-purple-700 text-sm font-semibold">
                <FileText size={14} />  {isFr ? "Ordonnance jointe" : "Rx attached"}
              </span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function PlatformOrders() {
  const t = useT();
  const { lang } = useLang();
  const isFr = lang === "fr";

  const [search, setSearch]         = useState("");
  const [statusFilter, setStatus]   = useState("all");
  const [typeFilter, setType]       = useState("all");
  const [selectedOrder, setSelected] = useState(null);

  // KPI summary
  const kpis = useMemo(() => ({
    total:     orders.length,
    pending:   orders.filter(o => o.status === "en_attente").length,
    enRoute:   orders.filter(o => o.status === "en_route").length,
    delivered: orders.filter(o => o.status === "livree").length,
    revenue:   orders.filter(o => o.status !== "rejete").reduce((s, o) => s + o.total, 0),
  }), []);

  // Filtered list
  const filtered = useMemo(() => {
    const q = search.toLowerCase().trim();
    return orders.filter(o => {
      if (statusFilter !== "all" && o.status !== statusFilter) return false;
      if (typeFilter   !== "all" && o.type   !== typeFilter)   return false;
      if (q) {
        const matchId     = o.id.toLowerCase().includes(q);
        const matchClient = o.client.toLowerCase().includes(q);
        const matchDrug   = o.drugs.some(d => d.name.toLowerCase().includes(q));
        if (!matchId && !matchClient && !matchDrug) return false;
      }
      return true;
    });
  }, [search, statusFilter, typeFilter]);

  const handleExport = () => {
    const headers = ["ID", isFr ? "Client" : "Client", isFr ? "Téléphone" : "Phone",
      isFr ? "Médicaments" : "Medications", isFr ? "Total (FCFA)" : "Total (FCFA)",
      isFr ? "Type" : "Type", isFr ? "Statut" : "Status", isFr ? "Date" : "Date"];
    const rows = filtered.map(o => [
      o.id, o.client, o.phone,
      o.drugs.map(d => `${d.name} ×${d.qty}`).join(" | "),
      o.total, o.type, o.status,
      new Date(o.createdAt).toLocaleDateString(isFr ? "fr-CM" : "en-CM"),
    ]);
    exportToCSV(headers, rows, `pharmago_orders_${new Date().toISOString().slice(0,10)}`);
  };

  const statusLabel = {
    all:         isFr ? "Tous"            : "All",
    en_attente:  isFr ? "En attente"      : "Pending",
    confirme:    isFr ? "Confirmées"      : "Confirmed",
    en_route:    isFr ? "En route"        : "In transit",
    livree:      isFr ? "Livrées"         : "Delivered",
    rejete:      isFr ? "Rejetées"        : "Rejected",
  };

  return (
    <div className="animate-fade-in-up">
      <PageHeader
        title={isFr ? "Toutes les Commandes" : "All Orders"}
        subtitle={isFr ? "Supervision globale des commandes sur la plateforme" : "Global order supervision across the platform"}
        action={
          <button
            onClick={handleExport}
            className="flex items-center gap-2 px-4 py-2 rounded-xl text-white text-sm font-semibold shadow-sm hover:opacity-90 transition-opacity"
            style={{ background: "#0F9B8E" }}
          >
            <Download size={15} /> {isFr ? "Exporter CSV" : "Export CSV"}
          </button>
        }
      />

      {/* KPI Banner */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-6">
        {[
          { label: isFr ? "Total commandes" : "Total orders",   value: kpis.total,     color: "#0D3B36", bg: "#F0F7F6", icon: ShoppingBag },
          { label: isFr ? "En attente"      : "Pending",        value: kpis.pending,   color: "#E8A33D", bg: "#FEF3DC", icon: Clock },
          { label: isFr ? "En livraison"    : "In transit",     value: kpis.enRoute,   color: "#7C3AED", bg: "#EDE9FE", icon: Truck },
          { label: isFr ? "Livrées"         : "Delivered",      value: kpis.delivered, color: "#16A34A", bg: "#DCFCE7", icon: CheckCircle },
          { label: isFr ? "Revenu total"    : "Total revenue",  value: formatFCFA(kpis.revenue), color: "#0F9B8E", bg: "#E6F7F6", icon: TrendingUp },
        ].map((kpi, i) => (
          <div key={i} className={`rounded-xl p-3 border card-hover animate-fade-in-up delay-${i * 75}`}
            style={{ background: "white", borderColor: "#DCE6E2" }}>
            <div className="flex items-center gap-2 mb-1">
              <div className="w-7 h-7 rounded-lg flex items-center justify-center" style={{ background: kpi.bg }}>
                <kpi.icon size={14} style={{ color: kpi.color }} />
              </div>
              <p className="text-xs text-gray-400 font-medium">{kpi.label}</p>
            </div>
            <p className="text-lg font-bold font-sora" style={{ color: kpi.color }}>{kpi.value}</p>
          </div>
        ))}
      </div>

      <Card>
        {/* Filter Bar */}
        <div className="p-4 border-b flex flex-wrap items-center gap-3" style={{ borderColor: "#DCE6E2" }}>
          {/* Search */}
          <div className="relative flex-1 min-w-[200px]">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder={isFr ? "Rechercher par ID, client, médicament..." : "Search by ID, client, medication..."}
              className="w-full pl-9 pr-4 py-2.5 text-sm rounded-xl border outline-none focus:border-[#0F9B8E] focus:ring-2 focus:ring-[#0F9B8E]/15 transition-all"
              style={{ borderColor: "#DCE6E2", background: "#FBFBFA" }}
            />
          </div>

          {/* Status filter */}
          <div className="flex items-center gap-1.5 flex-wrap">
            <Filter size={14} className="text-gray-400 shrink-0" />
            {ALL_STATUSES.map(s => (
              <button key={s}
                onClick={() => setStatus(s)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                  statusFilter === s
                    ? "text-white shadow-sm"
                    : "text-gray-500 bg-gray-100 hover:bg-gray-200"
                }`}
                style={statusFilter === s ? { background: STATUS_META[s]?.color || "#0F9B8E" } : {}}
              >
                {statusLabel[s]}
              </button>
            ))}
          </div>

          {/* Type filter */}
          <div className="flex items-center gap-1.5">
            {ALL_TYPES.map(tp => (
              <button key={tp}
                onClick={() => setType(tp)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                  typeFilter === tp
                    ? "bg-[#0D3B36] text-white"
                    : "text-gray-500 bg-gray-100 hover:bg-gray-200"
                }`}
              >
                {tp === "all" ? (isFr ? "Tous" : "All") : tp === "livraison" ? (isFr ? "Livraison" : "Delivery") : (isFr ? "Retrait" : "Pickup")}
              </button>
            ))}
          </div>

          <span className="text-xs text-gray-400 ml-auto">
            {filtered.length} / {orders.length} {isFr ? "commandes" : "orders"}
          </span>
        </div>

        {/* Table */}
        {filtered.length === 0 ? (
          <div className="py-20 flex flex-col items-center gap-3">
            <RefreshCw size={40} className="text-gray-200" />
            <p className="font-semibold text-gray-400">
              {isFr ? "Aucune commande trouvée" : "No orders found"}
            </p>
            <p className="text-sm text-gray-300">
              {isFr ? "Essayez de modifier vos filtres." : "Try adjusting your filters."}
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
                <Th>{isFr ? "Détails" : "Details"}</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((o, idx) => {
                const meta = STATUS_META[o.status] || {};
                return (
                  <tr
                    key={o.id}
                    className={`table-row-hover border-b transition-colors animate-fade-in-up`}
                    style={{ borderColor: "#F0F0F0", animationDelay: `${idx * 30}ms` }}
                  >
                    <Td>
                      <div className="flex items-center gap-2">
                        {meta.icon && (
                          <div className="w-6 h-6 rounded-md flex items-center justify-center shrink-0" style={{ background: meta.bg }}>
                            <meta.icon size={12} style={{ color: meta.color }} />
                          </div>
                        )}
                        <span className="font-mono font-semibold text-sm" style={{ color: "#0F9B8E" }}>{o.id}</span>
                      </div>
                    </Td>
                    <Td>
                      <div className="flex items-center gap-2">
                        <div
                          className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0"
                          style={{ background: "#0D3B36" }}
                        >
                          {getInitials(o.client)}
                        </div>
                        <div>
                          <p className="font-medium text-sm" style={{ color: "#0D3B36" }}>{o.client}</p>
                          <p className="text-xs text-gray-400">{o.phone}</p>
                        </div>
                      </div>
                    </Td>
                    <Td>
                      <p className="text-xs text-gray-600 max-w-[180px]">
                        {o.drugs.map(d => `${d.name} ×${d.qty}`).join(", ")}
                      </p>
                      {o.hasPrescription && (
                        <span className="text-[10px] text-purple-600 flex items-center gap-0.5 mt-0.5">
                          <FileText size={9} /> {isFr ? "Ord." : "Rx"}
                        </span>
                      )}
                    </Td>
                    <Td>
                      <span className="font-bold text-sm" style={{ color: "#0D3B36" }}>
                        {o.total.toLocaleString()} <span className="text-xs font-normal text-gray-400">FCFA</span>
                      </span>
                    </Td>
                    <Td>
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                        o.type === "livraison" ? "bg-blue-50 text-blue-700" : "bg-gray-100 text-gray-600"
                      }`}>
                        {o.type === "livraison" ? (isFr ? "🚚 Livraison" : "🚚 Delivery") : (isFr ? "🏪 Retrait" : "🏪 Pickup")}
                      </span>
                    </Td>
                    <Td><StatusBadge status={o.status} /></Td>
                    <Td>
                      <div>
                        <p className="text-xs text-gray-500">{timeAgo(o.createdAt, lang)}</p>
                        <p className="text-[10px] text-gray-300">
                          {new Date(o.createdAt).toLocaleString(isFr ? "fr-CM" : "en-CM", {
                            hour: "2-digit", minute: "2-digit", day: "2-digit", month: "short"
                          })}
                        </p>
                      </div>
                    </Td>
                    <Td>
                      <button
                        onClick={() => setSelected(o)}
                        className="p-1.5 rounded-lg text-gray-400 hover:text-[#0F9B8E] hover:bg-[#E6F7F6] transition-all"
                        title={isFr ? "Voir détails" : "View details"}
                      >
                        <Eye size={15} />
                      </button>
                    </Td>
                  </tr>
                );
              })}
            </tbody>
          </TableWrapper>
        )}

        {/* Table footer summary */}
        {filtered.length > 0 && (
          <div className="px-4 py-3 border-t flex items-center justify-between text-xs text-gray-400" style={{ borderColor: "#DCE6E2" }}>
            <span>{filtered.length} {isFr ? "commandes affichées" : "orders displayed"}</span>
            <span className="font-semibold" style={{ color: "#0D3B36" }}>
              {isFr ? "Total filtré" : "Filtered total"}: {formatFCFA(filtered.reduce((s, o) => s + o.total, 0))}
            </span>
          </div>
        )}
      </Card>

      {/* Order detail modal */}
      <OrderDetailModal
        order={selectedOrder}
        onClose={() => setSelected(null)}
        t={t}
        lang={lang}
      />
    </div>
  );
}
