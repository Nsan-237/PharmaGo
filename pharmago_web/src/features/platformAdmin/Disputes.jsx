import React, { useState } from "react";
import { AlertTriangle } from "lucide-react";
import { disputes as initialDisputes } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, Modal, PrimaryButton, SecondaryButton } from "../../components/shared/UI";

const priorityColors = {
  haute:   { bg:"#fee2e2", color:"#dc2626" },
  moyenne: { bg:"#FEF3DC", color:"#E8A33D" },
  faible:  { bg:"#f3f4f6", color:"#6b7280" },
};

export default function PlatformDisputes() {
  const t = useT();
  const [disputes, setDisputes] = useState(initialDisputes);
  const [selected, setSelected] = useState(null);

  const resolve     = (id) => { setDisputes(prev => prev.map(d => d.id===id ? {...d,status:"resolu"} : d)); setSelected(null); };
  const setInProgress=(id)=> { setDisputes(prev => prev.map(d => d.id===id ? {...d,status:"en_cours"} : d)); setSelected(null); };

  return (
    <div>
      <PageHeader title={t("disputes.title")} subtitle={`${disputes.filter(d=>d.status!=="resolu").length} ${t("disputes.subtitle")}`} />

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        {disputes.map(d => (
          <Card key={d.id} className="p-4 cursor-pointer hover:shadow-md transition-shadow" onClick={() => setSelected(d)}>
            <div className="flex items-start justify-between mb-3">
              <span className="font-mono text-sm font-bold" style={{ color: "#0F9B8E" }}>{d.id}</span>
              <div className="flex items-center gap-1.5">
                <span className="text-xs px-2 py-0.5 rounded-full font-medium" style={priorityColors[d.priority]}>
                  {t(`disputes.priority.${d.priority}`)}
                </span>
                <StatusBadge status={d.status} />
              </div>
            </div>
            <p className="text-sm font-semibold mb-1" style={{ color: "#0D3B36" }}>{d.client}</p>
            <p className="text-xs text-gray-500 mb-2">{d.pharmacy}</p>
            <p className="text-sm text-gray-600 leading-relaxed">{d.reason}</p>
            <p className="text-xs text-gray-400 mt-3">{new Date(d.createdAt).toLocaleDateString([], {day:"2-digit",month:"short",year:"numeric"})}</p>
          </Card>
        ))}
      </div>

      <Modal open={!!selected} onClose={() => setSelected(null)} title={`${t("disputes.title")} ${selected?.id}`}>
        {selected && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 rounded-lg" style={{ background: "#F6F5EF" }}>
                <p className="text-xs text-gray-400 mb-0.5">{t("disputes.colClient")}</p>
                <p className="font-semibold" style={{ color: "#0D3B36" }}>{selected.client}</p>
              </div>
              <div className="p-3 rounded-lg" style={{ background: "#F6F5EF" }}>
                <p className="text-xs text-gray-400 mb-0.5">{t("disputes.colOrder")}</p>
                <p className="font-semibold font-mono" style={{ color: "#0F9B8E" }}>{selected.orderId}</p>
              </div>
            </div>
            <div className="p-3 rounded-lg" style={{ background: "#F6F5EF" }}>
              <p className="text-xs text-gray-400 mb-0.5">{t("disputes.colPharmacy")}</p>
              <p className="font-semibold" style={{ color: "#0D3B36" }}>{selected.pharmacy}</p>
            </div>
            <div className="p-3 rounded-xl border-l-4" style={{ background: "#FEF3DC", borderLeftColor: "#E8A33D" }}>
              <p className="text-xs text-gray-500 mb-1">{t("disputes.colReason")}</p>
              <p className="font-medium" style={{ color: "#0D3B36" }}>{selected.reason}</p>
            </div>
            <div className="flex gap-3 pt-2">
              {selected.status !== "resolu" && (
                <PrimaryButton onClick={() => resolve(selected.id)} className="flex-1 justify-center">
                  {t("common.resolve")}
                </PrimaryButton>
              )}
              {selected.status === "ouvert" && (
                <SecondaryButton onClick={() => setInProgress(selected.id)} className="flex-1 justify-center">
                  {t("common.takeCharge")}
                </SecondaryButton>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
