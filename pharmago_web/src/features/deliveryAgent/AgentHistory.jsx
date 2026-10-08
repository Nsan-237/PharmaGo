import React, { useState, useEffect, useCallback } from "react";
import { RefreshCw, Loader2, Package, Download } from "lucide-react";
import { apiGetAgentOrders, normalizeOrder } from "../../utils/api";
import { useT, useLang } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";
import { exportToCSV } from "../../utils/exportUtils";

export default function AgentHistory() {
  const t = useT();
  const { lang } = useLang();
  const isFr = lang === "fr";

  const [delivered, setDelivered] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchHistory = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    else setRefreshing(true);
    try {
      const data = await apiGetAgentOrders();
      setDelivered((data.delivered || []).map(normalizeOrder));
    } catch (err) {
      console.error("Failed to fetch agent history:", err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchHistory();
  }, [fetchHistory]);

  const handleExport = () => {
    const headers = ["ID", isFr ? "Client" : "Client", isFr ? "Adresse" : "Address", isFr ? "Médicaments" : "Drugs", isFr ? "Total" : "Total", isFr ? "Statut" : "Status"];
    const rows = delivered.map(d => [
      d.id,
      d.client,
      d.address,
      d.drugsSummary || (d.drugs || []).map(i => `${i.name} x${i.qty}`).join(", "),
      d.total,
      d.status,
    ]);
    exportToCSV(headers, rows, `mes_livraisons_${new Date().toISOString().slice(0, 10)}`);
  };

  return (
    <div>
      <PageHeader
        title={t("agentHist.title")}
        subtitle={`${delivered.length} ${t("agentHist.subtitle")}`}
        action={
          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchHistory(true)}
              disabled={refreshing}
              className="flex items-center gap-2 px-3 py-2 rounded-xl border text-sm font-medium hover:bg-gray-50 transition-all"
              style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
            >
              <RefreshCw size={14} className={refreshing ? "animate-spin" : ""} />
              {isFr ? "Actualiser" : "Refresh"}
            </button>
            {delivered.length > 0 && (
              <button
                onClick={handleExport}
                className="flex items-center gap-2 px-4 py-2 rounded-xl text-white text-sm font-semibold hover:opacity-90 shadow-sm"
                style={{ background: "#0F9B8E" }}
              >
                <Download size={14} /> {isFr ? "Exporter" : "Export"}
              </button>
            )}
          </div>
        }
      />

      <Card>
        {loading ? (
          <div className="py-16 flex flex-col items-center gap-3">
            <Loader2 size={36} className="animate-spin" style={{ color: "#0F9B8E" }} />
            <p className="text-gray-400 font-medium text-sm">
              {isFr ? "Chargement de l'historique…" : "Loading history…"}
            </p>
          </div>
        ) : delivered.length === 0 ? (
          <div className="py-16 text-center">
            <Package size={40} className="mx-auto text-gray-300 mb-2" />
            <p className="font-semibold text-gray-500">
              {isFr ? "Aucune livraison terminée" : "No completed deliveries"}
            </p>
            <p className="text-xs text-gray-400 mt-1">
              {isFr ? "Vos courses finalisées apparaîtront ici." : "Your completed orders will be listed here."}
            </p>
          </div>
        ) : (
          <TableWrapper>
            <thead>
              <tr>
                <Th>{t("agentHist.colId")}</Th>
                <Th>{t("agentHist.colClient")}</Th>
                <Th>{t("agentHist.colAddress")}</Th>
                <Th>{t("agentHist.colDrugs")}</Th>
                <Th>{t("agentHist.colTotal")}</Th>
                <Th>{t("agentHist.colStatus")}</Th>
              </tr>
            </thead>
            <tbody>
              {delivered.map(d => (
                <tr key={d._id || d.id} className="hover:bg-gray-50 border-b" style={{ borderColor: "#F0F0F0" }}>
                  <Td><span className="font-mono font-semibold text-sm" style={{ color: "#0F9B8E" }}>{d.id}</span></Td>
                  <Td><span className="font-medium text-sm" style={{ color: "#0D3B36" }}>{d.client}</span></Td>
                  <Td><span className="text-xs text-gray-500 max-w-[200px] truncate block">{d.address || "—"}</span></Td>
                  <Td>
                    <span className="text-xs text-gray-600 max-w-[200px] truncate block">
                      {d.drugsSummary || (d.drugs || []).map(i => `${i.name} x${i.qty}`).join(", ") || "—"}
                    </span>
                  </Td>
                  <Td><span className="font-semibold text-sm">{(d.total || 0).toLocaleString()} FCFA</span></Td>
                  <Td><StatusBadge status={d.status} /></Td>
                </tr>
              ))}
            </tbody>
          </TableWrapper>
        )}
      </Card>
    </div>
  );
}
