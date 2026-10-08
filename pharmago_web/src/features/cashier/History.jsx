import React, { useState, useMemo, useEffect, useCallback } from "react";
import {
  Search,
  Download,
  CheckCircle,
  XCircle,
  History as HistoryIcon,
  Package,
  RefreshCw,
  Loader2,
} from "lucide-react";
import { useT, useLang } from "../../i18n/TranslationContext";
import { apiGetOrders, normalizeOrder } from "../../utils/api";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";
import { timeAgo, formatFCFA, getInitials } from "../../utils/timeUtils";
import { exportToCSV } from "../../utils/exportUtils";

const PROCESSED_STATUSES = ["confirme", "en_preparation", "pret", "livree", "rejete", "en_route"];

export default function CashierHistory() {
  const t = useT();
  const { lang } = useLang();
  const isFr = lang === "fr";
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  const fetchOrders = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    else setRefreshing(true);
    try {
      const data = await apiGetOrders();
      setOrders((data.orders || []).map(normalizeOrder));
    } catch (err) {
      console.error("Failed to fetch cashier history:", err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchOrders();
    const interval = setInterval(() => fetchOrders(true), 30_000);
    return () => clearInterval(interval);
  }, [fetchOrders]);

  const processed = useMemo(
    () => orders.filter((o) => PROCESSED_STATUSES.includes(o.status)),
    [orders]
  );

  const filtered = useMemo(() => {
    const q = search.toLowerCase().trim();
    return processed.filter((o) => {
      if (statusFilter !== "all" && o.status !== statusFilter) return false;
      if (q) {
        return (
          o.id.toLowerCase().includes(q) ||
          o.client.toLowerCase().includes(q) ||
          (o.drugs && o.drugs.some((d) => d.name.toLowerCase().includes(q)))
        );
      }
      return true;
    });
  }, [processed, search, statusFilter]);

  // KPI stats
  const stats = useMemo(
    () => ({
      confirmed: processed.filter(
        (o) =>
          o.status === "confirme" ||
          o.status === "en_preparation" ||
          o.status === "pret" ||
          o.status === "livree" ||
          o.status === "en_route"
      ).length,
      rejected: processed.filter((o) => o.status === "rejete").length,
      revenue: processed
        .filter((o) => o.status !== "rejete")
        .reduce((s, o) => s + (o.total || 0), 0),
    }),
    [processed]
  );

  const handleExport = () => {
    const headers = [
      "ID",
      isFr ? "Client" : "Client",
      isFr ? "Médicaments" : "Medications",
      isFr ? "Total" : "Total",
      isFr ? "Statut" : "Status",
      isFr ? "Date" : "Date",
    ];
    const rows = filtered.map((o) => [
      o.id,
      o.client,
      o.drugs && o.drugs.length > 0
        ? o.drugs.map((d) => `${d.name} ×${d.qty}`).join(" | ")
        : o.drugsSummary || "—",
      o.total,
      o.status,
      new Date(o.createdAt).toLocaleDateString(isFr ? "fr-CM" : "en-CM"),
    ]);
    exportToCSV(headers, rows, `pharmago_history_${new Date().toISOString().slice(0, 10)}`);
  };

  return (
    <div className="animate-fade-in-up">
      <PageHeader
        title={isFr ? "Historique des Commandes" : "Order History"}
        subtitle={
          isFr
            ? `${processed.length} commandes traitées`
            : `${processed.length} orders processed`
        }
        action={
          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchOrders(true)}
              disabled={refreshing}
              className="flex items-center gap-2 px-3 py-2 rounded-xl border text-sm font-medium hover:bg-gray-50 transition-all"
              style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
            >
              <RefreshCw size={14} className={refreshing ? "animate-spin" : ""} />
              {isFr ? "Actualiser" : "Refresh"}
            </button>
            <button
              onClick={handleExport}
              className="flex items-center gap-2 px-4 py-2 rounded-xl text-white text-sm font-semibold hover:opacity-90 transition-opacity"
              style={{ background: "#0F9B8E" }}
            >
              <Download size={14} /> {isFr ? "Exporter" : "Export"}
            </button>
          </div>
        }
      />

      {/* KPI Summary */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div
          className="bg-white rounded-xl border p-4 flex items-center gap-3 card-hover"
          style={{ borderColor: "#DCE6E2" }}
        >
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{ background: "#DCFCE7" }}
          >
            <CheckCircle size={18} style={{ color: "#16A34A" }} />
          </div>
          <div>
            <p className="text-xs text-gray-400">{isFr ? "Traitées / Confirmées" : "Processed / Confirmed"}</p>
            <p className="text-xl font-bold font-sora" style={{ color: "#0D3B36" }}>
              {stats.confirmed}
            </p>
          </div>
        </div>
        <div
          className="bg-white rounded-xl border p-4 flex items-center gap-3 card-hover"
          style={{ borderColor: "#DCE6E2" }}
        >
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{ background: "#FEE2E2" }}
          >
            <XCircle size={18} style={{ color: "#DC2626" }} />
          </div>
          <div>
            <p className="text-xs text-gray-400">{isFr ? "Rejetées" : "Rejected"}</p>
            <p className="text-xl font-bold font-sora" style={{ color: "#0D3B36" }}>
              {stats.rejected}
            </p>
          </div>
        </div>
        <div
          className="bg-white rounded-xl border p-4 flex items-center gap-3 card-hover"
          style={{ borderColor: "#DCE6E2" }}
        >
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{ background: "#E6F7F6" }}
          >
            <Package size={18} style={{ color: "#0F9B8E" }} />
          </div>
          <div>
            <p className="text-xs text-gray-400">{isFr ? "Revenu traité" : "Revenue handled"}</p>
            <p className="text-base font-bold font-sora" style={{ color: "#0D3B36" }}>
              {formatFCFA(stats.revenue)}
            </p>
          </div>
        </div>
      </div>

      <Card>
        {/* Filter bar */}
        <div
          className="p-4 border-b flex flex-wrap items-center gap-3"
          style={{ borderColor: "#DCE6E2" }}
        >
          <div className="relative flex-1 min-w-[200px]">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={isFr ? "Rechercher une commande..." : "Search an order..."}
              className="w-full pl-9 pr-4 py-2.5 text-sm rounded-xl border outline-none focus:border-[#0F9B8E] transition-all"
              style={{ borderColor: "#DCE6E2", background: "#FBFBFA" }}
            />
          </div>
          <div className="flex gap-1.5 flex-wrap">
            {["all", "confirme", "en_route", "livree", "rejete"].map((s) => (
              <button
                key={s}
                onClick={() => setStatusFilter(s)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                  statusFilter === s
                    ? "bg-[#0D3B36] text-white"
                    : "bg-gray-100 text-gray-500 hover:bg-gray-200"
                }`}
              >
                {
                  {
                    all: isFr ? "Tous" : "All",
                    confirme: isFr ? "Confirmées" : "Confirmed",
                    en_route: isFr ? "En route" : "In transit",
                    livree: isFr ? "Livrées" : "Delivered",
                    rejete: isFr ? "Rejetées" : "Rejected",
                  }[s]
                }
              </button>
            ))}
          </div>
          <span className="text-xs text-gray-400">
            {filtered.length} / {processed.length}
          </span>
        </div>

        {loading ? (
          <div className="py-20 flex flex-col items-center gap-3">
            <Loader2 size={36} className="animate-spin" style={{ color: "#0F9B8E" }} />
            <p className="text-gray-400 font-medium text-sm">
              {isFr ? "Chargement de l'historique…" : "Loading history…"}
            </p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="py-20 flex flex-col items-center gap-3">
            <HistoryIcon size={44} className="text-gray-200" />
            <p className="font-semibold text-gray-400">
              {isFr ? "Aucun historique trouvé" : "No history found"}
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
              </tr>
            </thead>
            <tbody>
              {filtered.map((o, idx) => (
                <tr
                  key={o._id || o.id}
                  className="table-row-hover border-b animate-fade-in-up"
                  style={{ borderColor: "#F0F0F0", animationDelay: `${idx * 25}ms` }}
                >
                  <Td>
                    <span className="font-mono font-semibold text-sm" style={{ color: "#0F9B8E" }}>
                      {o.id}
                    </span>
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
                        <p className="font-medium text-sm" style={{ color: "#0D3B36" }}>
                          {o.client}
                        </p>
                        <p className="text-xs text-gray-400">{o.phone}</p>
                      </div>
                    </div>
                  </Td>
                  <Td>
                    <p className="text-xs text-gray-600 max-w-[180px] truncate">
                      {o.drugs && o.drugs.length > 0
                        ? o.drugs.map((d) => `${d.name} ×${d.qty}`).join(", ")
                        : o.drugsSummary || "—"}
                    </p>
                  </Td>
                  <Td>
                    <span className="font-bold text-sm" style={{ color: "#0D3B36" }}>
                      {(o.total || 0).toLocaleString()}{" "}
                      <span className="text-xs font-normal text-gray-400">FCFA</span>
                    </span>
                  </Td>
                  <Td>
                    <span
                      className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                        o.type === "livraison"
                          ? "bg-blue-50 text-blue-700"
                          : "bg-gray-100 text-gray-600"
                      }`}
                    >
                      {o.type === "livraison"
                        ? isFr
                          ? "🚚 Livraison"
                          : "🚚 Delivery"
                        : isFr
                        ? "🏪 Retrait"
                        : "🏪 Pickup"}
                    </span>
                  </Td>
                  <Td>
                    <StatusBadge status={o.status} />
                  </Td>
                  <Td>
                    <div>
                      <p className="text-xs text-gray-500">{timeAgo(o.createdAt, lang)}</p>
                      <p className="text-[10px] text-gray-300">
                        {new Date(o.createdAt).toLocaleString(isFr ? "fr-CM" : "en-CM", {
                          hour: "2-digit",
                          minute: "2-digit",
                          day: "2-digit",
                          month: "short",
                        })}
                      </p>
                    </div>
                  </Td>
                </tr>
              ))}
            </tbody>
          </TableWrapper>
        )}

        {filtered.length > 0 && (
          <div
            className="px-4 py-3 border-t flex items-center justify-between text-xs text-gray-400"
            style={{ borderColor: "#DCE6E2" }}
          >
            <span>
              {filtered.length} {isFr ? "commandes" : "orders"}
            </span>
            <span className="font-semibold" style={{ color: "#0D3B36" }}>
              {formatFCFA(
                filtered
                  .filter((o) => o.status !== "rejete")
                  .reduce((s, o) => s + (o.total || 0), 0)
              )}
            </span>
          </div>
        )}
      </Card>
    </div>
  );
}
