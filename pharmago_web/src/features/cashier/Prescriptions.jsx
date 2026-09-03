import React, { useState } from "react";
import { CheckCircle, XCircle, Eye } from "lucide-react";
import { prescriptions as initialPx } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, Modal } from "../../components/shared/UI";

export default function CashierPrescriptions() {
  const t = useT();
  const [prescriptions, setPrescriptions] = useState(initialPx);
  const [preview, setPreview] = useState(null);

  const verify = (id) => setPrescriptions(prev => prev.map(p => p.id===id ? {...p,status:"verifie"} : p));
  const reject = (id) => setPrescriptions(prev => prev.map(p => p.id===id ? {...p,status:"rejete"} : p));

  return (
    <div>
      <PageHeader title={t("rx.title")} subtitle={t("rx.subtitle")} />
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
        {prescriptions.map(p => (
          <Card key={p.id} className="overflow-hidden">
            <div className="relative">
              <img src={p.imageUrl} alt={t("rx.title")} className="w-full h-36 object-cover" />
              <button onClick={() => setPreview(p)} className="absolute inset-0 flex items-center justify-center bg-black/20 opacity-0 hover:opacity-100 transition-opacity">
                <Eye size={24} className="text-white" />
              </button>
            </div>
            <div className="p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="font-mono text-xs font-semibold" style={{ color: "#0F9B8E" }}>{p.id}</span>
                <StatusBadge status={p.status} />
              </div>
              <p className="font-semibold text-sm" style={{ color: "#0D3B36" }}>{p.client}</p>
              <p className="text-xs text-gray-500 mt-0.5">{p.drug}</p>
              <p className="text-xs text-gray-400 mt-1">{new Date(p.uploadedAt).toLocaleString([], {day:"2-digit",month:"short",hour:"2-digit",minute:"2-digit"})}</p>
              {p.status === "en_attente" && (
                <div className="flex gap-2 mt-3">
                  <button onClick={() => verify(p.id)} className="flex-1 flex items-center justify-center gap-1 py-2 rounded-lg text-white text-xs font-semibold" style={{ background: "#0F9B8E" }}>
                    <CheckCircle size={13} /> {t("rx.verify")}
                  </button>
                  <button onClick={() => reject(p.id)} className="flex-1 flex items-center justify-center gap-1 py-2 rounded-lg text-white text-xs font-semibold bg-red-500">
                    <XCircle size={13} /> {t("rx.reject")}
                  </button>
                </div>
              )}
            </div>
          </Card>
        ))}
      </div>
      <Modal open={!!preview} onClose={() => setPreview(null)} title={`${t("rx.title")} — ${preview?.client}`}>
        {preview && <img src={preview.imageUrl} alt={t("rx.title")} className="w-full rounded-lg" />}
      </Modal>
    </div>
  );
}
