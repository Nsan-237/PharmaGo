import React, { useState } from "react";
import { MapPin, Package, ChevronRight } from "lucide-react";
import { deliveries as initialDeliveries } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card } from "../../components/shared/UI";

const statusFlow = ["assignee","en_route","livree"];

export default function AgentDeliveries() {
  const t = useT();
  const [deliveries, setDeliveries] = useState(initialDeliveries);
  const [tab, setTab] = useState("assignee");

  const tabs = [
    { key: "assignee", labelKey: "agent.tabAssigned" },
    { key: "en_route", labelKey: "agent.tabEnRoute" },
    { key: "livree",   labelKey: "agent.tabDone" },
  ];

  const advance = (id) => {
    setDeliveries(prev => prev.map(d => {
      if (d.id !== id) return d;
      const idx = statusFlow.indexOf(d.status);
      return { ...d, status: statusFlow[Math.min(idx+1, statusFlow.length-1)] };
    }));
  };

  const filtered = deliveries.filter(d => d.status === tab);

  return (
    <div>
      <PageHeader title={t("agent.title")} subtitle={t("agent.subtitle")} />

      <div className="flex gap-2 mb-5">
        {tabs.map(tb => (
          <button key={tb.key} onClick={() => setTab(tb.key)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${tab===tb.key ? "text-white" : "bg-white text-gray-600 border"}`}
            style={tab===tb.key ? { background: "#0F9B8E" } : { borderColor: "#DCE6E2" }}
          >
            {t(tb.labelKey)} ({deliveries.filter(d=>d.status===tb.key).length})
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <Card className="p-12 text-center">
          <Package size={36} className="mx-auto mb-3 text-gray-300" />
          <p className="text-gray-500 font-medium">{t("agent.empty")}</p>
        </Card>
      ) : (
        <div className="space-y-4">
          {filtered.map(d => (
            <Card key={d.id} className="p-4">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: "#e6f7f6" }}>
                    <Package size={18} style={{ color: "#0F9B8E" }} />
                  </div>
                  <div>
                    <p className="font-mono font-bold text-sm" style={{ color: "#0F9B8E" }}>{d.id}</p>
                    <p className="text-xs text-gray-400">{d.orderId}</p>
                  </div>
                </div>
                <StatusBadge status={d.status} />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4">
                <div>
                  <p className="text-xs text-gray-400 mb-0.5">{t("agent.colClient")}</p>
                  <p className="text-sm font-semibold" style={{ color: "#0D3B36" }}>{d.client}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 mb-0.5">{t("agent.colPharmacy")}</p>
                  <p className="text-sm font-semibold" style={{ color: "#0D3B36" }}>{d.pharmacy}</p>
                </div>
                <div className="sm:col-span-2">
                  <p className="text-xs text-gray-400 mb-0.5 flex items-center gap-1"><MapPin size={10} /> {t("agent.colAddress")}</p>
                  <p className="text-sm" style={{ color: "#0D3B36" }}>{d.address}</p>
                </div>
                <div className="sm:col-span-2">
                  <p className="text-xs text-gray-400 mb-0.5">{t("agent.colDrugs")}</p>
                  <p className="text-sm text-gray-600">{d.drugs}</p>
                </div>
              </div>

              <div className="flex items-center justify-between border-t pt-3" style={{ borderColor: "#DCE6E2" }}>
                <p className="font-bold font-sora" style={{ color: "#0D3B36" }}>{d.total.toLocaleString()} FCFA</p>
                {d.status === "assignee" && (
                  <button onClick={() => advance(d.id)}
                    className="flex items-center gap-2 px-4 py-2 rounded-lg text-white text-sm font-semibold hover:opacity-90"
                    style={{ background: "#0F9B8E" }}>
                    {t("agent.accept")} <ChevronRight size={14} />
                  </button>
                )}
                {d.status === "en_route" && (
                  <button onClick={() => advance(d.id)}
                    className="flex items-center gap-2 px-4 py-2 rounded-lg text-white text-sm font-semibold bg-green-600 hover:bg-green-700">
                    {t("agent.markDelivered")} <ChevronRight size={14} />
                  </button>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
