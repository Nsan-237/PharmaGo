import React, { useState } from "react";
import { Plus, Pencil, Trash2, Phone } from "lucide-react";
import { agents as initialAgents } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td, PrimaryButton, SecondaryButton, Modal, InputField } from "../../components/shared/UI";

export default function PharmaAgents() {
  const t = useT();
  const [agents, setAgents] = useState(initialAgents);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState({ name: "", phone: "", zone: "" });

  const handleSave = () => {
    setAgents(prev => [...prev, { id: Date.now(), ...form, status: "hors_ligne", deliveriesToday: 0 }]);
    setModalOpen(false);
    setForm({ name: "", phone: "", zone: "" });
  };

  return (
    <div>
      <PageHeader
        title={t("agents.title")}
        subtitle={`${agents.length} ${t("agents.subtitle")}`}
        action={<PrimaryButton onClick={() => setModalOpen(true)}><Plus size={16} /> {t("agents.addBtn")}</PrimaryButton>}
      />

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        {agents.map(a => (
          <Card key={a.id} className="p-4">
            <div className="flex items-start justify-between mb-3">
              <div className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold font-sora" style={{ background: "#0F9B8E" }}>
                {a.name.split(" ").map(n=>n[0]).join("").slice(0,2)}
              </div>
              <StatusBadge status={a.status} />
            </div>
            <p className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{a.name}</p>
            <p className="text-xs text-gray-500 mt-0.5 flex items-center gap-1"><Phone size={10} />{a.phone}</p>
            <p className="text-xs text-gray-400 mt-1">{t("agents.zone")}: {a.zone}</p>
            <div className="flex items-center justify-between mt-3 pt-3 border-t" style={{ borderColor: "#DCE6E2" }}>
              <p className="text-xs text-gray-500">{a.deliveriesToday} {t("agents.deliveriesToday")}</p>
              <div className="flex gap-1">
                <button className="p-1 rounded hover:bg-blue-50 text-blue-500"><Pencil size={13} /></button>
                <button onClick={() => setAgents(prev=>prev.filter(ag=>ag.id!==a.id))} className="p-1 rounded hover:bg-red-50 text-red-500"><Trash2 size={13} /></button>
              </div>
            </div>
          </Card>
        ))}
      </div>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={t("agents.modalTitle")}>
        <div className="space-y-4">
          <InputField label={t("agents.fieldName")}  value={form.name}  onChange={e => setForm(f=>({...f,name:e.target.value}))}  placeholder={t("agents.fieldNamePh")}  required />
          <InputField label={t("agents.fieldPhone")} value={form.phone} onChange={e => setForm(f=>({...f,phone:e.target.value}))} placeholder={t("agents.fieldPhonePh")} required />
          <InputField label={t("agents.fieldZone")}  value={form.zone}  onChange={e => setForm(f=>({...f,zone:e.target.value}))}  placeholder={t("agents.fieldZonePh")}  required />
          <div className="flex gap-3 pt-2">
            <PrimaryButton onClick={handleSave} className="flex-1 justify-center">{t("common.add")}</PrimaryButton>
            <SecondaryButton onClick={() => setModalOpen(false)} className="flex-1 justify-center">{t("common.cancel")}</SecondaryButton>
          </div>
        </div>
      </Modal>
    </div>
  );
}
