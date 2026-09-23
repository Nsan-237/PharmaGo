import React, { useState, useEffect } from "react";
import { Plus, Pencil, Trash2, Phone, MapPin, CheckCircle, AlertTriangle, Search, Truck } from "lucide-react";
import { agents as initialAgents } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { useLang } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { useToast } from "../../components/shared/Toast";
import { getInitials } from "../../utils/timeUtils";
import { PageHeader, Card, Modal, InputField, PrimaryButton, SecondaryButton } from "../../components/shared/UI";

// Agent API stubs (wired to server when ready, falls back gracefully)
async function apiCreateAgent(data)          { const r = await fetch("/api/agents", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data) }); if (!r.ok) throw new Error(); return r.json(); }
async function apiUpdateAgent(id, data)      { const r = await fetch(`/api/agents/${id}`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data) }); if (!r.ok) throw new Error(); return r.json(); }
async function apiDeleteAgent(id)            { const r = await fetch(`/api/agents/${id}`, { method: "DELETE" }); if (!r.ok) throw new Error(); }
async function apiToggleAgentStatus(id, st)  { const r = await fetch(`/api/agents/${id}/status`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ status: st }) }); if (!r.ok) throw new Error(); }

const EMPTY_FORM = { name: "", phone: "+237 6", zone: "", email: "" };

const STATUS_COLORS = {
  en_ligne:    { dot: "#16A34A", bg: "#DCFCE7", label: { fr: "En ligne",     en: "Online" } },
  hors_ligne:  { dot: "#6B7280", bg: "#F3F4F6", label: { fr: "Hors ligne",   en: "Offline" } },
  en_livraison:{ dot: "#2563EB", bg: "#DBEAFE", label: { fr: "En livraison", en: "Delivering" } },
};

export default function PharmaAgents() {
  const t = useT();
  const { lang } = useLang();
  const isFr = lang === "fr";
  const toast = useToast();

  const [agents, setAgents] = useState(initialAgents);
  const [search, setSearch] = useState("");

  // Modals
  const [addOpen, setAddOpen]         = useState(false);
  const [editTarget, setEditTarget]   = useState(null); // agent being edited
  const [deleteTarget, setDeleteTarget] = useState(null); // agent to delete

  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);

  // Filtered list
  const filtered = agents.filter(a => {
    const q = search.toLowerCase();
    return a.name.toLowerCase().includes(q) || a.zone.toLowerCase().includes(q) || (a.phone || "").includes(q);
  });

  // KPI
  const online    = agents.filter(a => a.status === "en_ligne").length;
  const delivering= agents.filter(a => a.status === "en_livraison").length;
  const offline   = agents.filter(a => a.status === "hors_ligne").length;

  // ── Handlers ───────────────────────────────────────────────────────────────

  const openAdd = () => { setForm(EMPTY_FORM); setAddOpen(true); };

  const openEdit = (agent) => {
    setForm({ name: agent.name, phone: agent.phone, zone: agent.zone, email: agent.email || "" });
    setEditTarget(agent);
  };

  const handleSave = async () => {
    if (!form.name.trim() || !form.phone.trim() || !form.zone.trim()) {
      toast.warning(isFr ? "Veuillez remplir tous les champs requis." : "Please fill all required fields.");
      return;
    }
    setSaving(true);
    if (editTarget) {
      // UPDATE
      try { await apiUpdateAgent(editTarget.id, form); } catch (_) {}
      setAgents(prev => prev.map(a => a.id === editTarget.id ? { ...a, ...form } : a));
      toast.success(
        isFr ? `"${form.name}" mis à jour.` : `"${form.name}" updated.`,
        isFr ? "Agent modifié" : "Agent updated"
      );
      setEditTarget(null);
    } else {
      // CREATE
      const newAgent = { id: Date.now(), ...form, status: "hors_ligne", deliveriesToday: 0 };
      try {
        const res = await apiCreateAgent(form);
        if (res?.agent?.id) newAgent.id = res.agent.id;
      } catch (_) {}
      setAgents(prev => [newAgent, ...prev]);
      toast.success(
        isFr ? `"${form.name}" ajouté comme agent.` : `"${form.name}" added as agent.`,
        isFr ? "Agent créé" : "Agent created"
      );
      setAddOpen(false);
    }
    setSaving(false);
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try { await apiDeleteAgent(deleteTarget.id); } catch (_) {}
    setAgents(prev => prev.filter(a => a.id !== deleteTarget.id));
    toast.success(
      isFr ? `"${deleteTarget.name}" retiré de l'équipe.` : `"${deleteTarget.name}" removed from the team.`,
      isFr ? "Agent supprimé" : "Agent deleted"
    );
    setDeleteTarget(null);
  };

  const toggleStatus = async (agent) => {
    const next = agent.status === "en_ligne" ? "hors_ligne" : "en_ligne";
    try { await apiToggleAgentStatus(agent.id, next); } catch (_) {}
    setAgents(prev => prev.map(a => a.id === agent.id ? { ...a, status: next } : a));
    const meta = STATUS_COLORS[next];
    toast.info(
      isFr ? `"${agent.name}" est maintenant ${meta.label.fr}.` : `"${agent.name}" is now ${meta.label.en}.`
    );
  };

  return (
    <div className="animate-fade-in-up">
      <PageHeader
        title={isFr ? "Agents de Livraison" : "Delivery Agents"}
        subtitle={isFr ? `${agents.length} agents enregistrés` : `${agents.length} registered agents`}
        action={
          <PrimaryButton onClick={openAdd}>
            <Plus size={15} /> {isFr ? "Ajouter un agent" : "Add agent"}
          </PrimaryButton>
        }
      />

      {/* KPI row */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        {[
          { label: isFr ? "En ligne" : "Online",       value: online,     color: "#16A34A", bg: "#DCFCE7" },
          { label: isFr ? "En livraison" : "Delivering", value: delivering, color: "#2563EB", bg: "#DBEAFE" },
          { label: isFr ? "Hors ligne" : "Offline",    value: offline,    color: "#6B7280", bg: "#F3F4F6" },
        ].map((k, i) => (
          <div key={i} className="bg-white rounded-xl border p-4 flex items-center gap-3 card-hover" style={{ borderColor: "#DCE6E2" }}>
            <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: k.bg }}>
              <Truck size={18} style={{ color: k.color }} />
            </div>
            <div>
              <p className="text-xs text-gray-400">{k.label}</p>
              <p className="text-xl font-bold font-sora" style={{ color: "#0D3B36" }}>{k.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Search bar */}
      <div className="relative mb-5 max-w-sm">
        <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder={isFr ? "Rechercher un agent..." : "Search an agent..."}
          className="w-full pl-9 pr-4 py-2.5 text-sm rounded-xl border outline-none focus:border-[#0F9B8E] transition-all"
          style={{ borderColor: "#DCE6E2", background: "#FBFBFA" }}
        />
      </div>

      {/* Agent cards grid */}
      {filtered.length === 0 ? (
        <div className="py-20 text-center">
          <Truck size={48} className="mx-auto text-gray-200 mb-3" />
          <p className="font-semibold text-gray-400">{isFr ? "Aucun agent trouvé" : "No agents found"}</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-4">
          {filtered.map((a, idx) => {
            const meta = STATUS_COLORS[a.status] || STATUS_COLORS.hors_ligne;
            return (
              <Card key={a.id} className={`p-4 card-hover animate-fade-in-up`} style={{ animationDelay: `${idx * 40}ms` }}>
                {/* Header row */}
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-11 h-11 rounded-full flex items-center justify-center text-white font-bold font-sora text-sm shrink-0"
                      style={{ background: "#0F9B8E" }}
                    >
                      {getInitials(a.name)}
                    </div>
                    <div className="min-w-0">
                      <p className="font-semibold font-sora text-sm truncate" style={{ color: "#0D3B36" }}>{a.name}</p>
                      <p className="text-xs text-gray-400 flex items-center gap-1">
                        <Phone size={9} /> {a.phone}
                      </p>
                    </div>
                  </div>
                  {/* Status pill */}
                  <span
                    className="text-[10px] font-bold px-2 py-1 rounded-full shrink-0 cursor-pointer select-none"
                    style={{ background: meta.bg, color: meta.dot }}
                    onClick={() => toggleStatus(a)}
                    title={isFr ? "Cliquer pour basculer" : "Click to toggle"}
                  >
                    <span className="inline-block w-1.5 h-1.5 rounded-full mr-1 align-middle" style={{ background: meta.dot }} />
                    {meta.label[lang] || meta.label.fr}
                  </span>
                </div>

                {/* Zone */}
                <p className="text-xs text-gray-500 flex items-center gap-1 mb-3">
                  <MapPin size={10} />
                  {a.zone}
                </p>

                {/* Deliveries today */}
                <div className="flex items-center justify-between pt-3 border-t" style={{ borderColor: "#DCE6E2" }}>
                  <div>
                    <p className="text-xs text-gray-400">{isFr ? "Livraisons aujourd'hui" : "Today's deliveries"}</p>
                    <p className="font-bold text-lg font-sora" style={{ color: "#0D3B36" }}>{a.deliveriesToday}</p>
                  </div>
                  <div className="flex gap-1.5">
                    <button
                      onClick={() => openEdit(a)}
                      className="p-1.5 rounded-lg hover:bg-blue-50 text-blue-500 transition-all"
                      title={isFr ? "Modifier" : "Edit"}
                    >
                      <Pencil size={14} />
                    </button>
                    <button
                      onClick={() => setDeleteTarget(a)}
                      className="p-1.5 rounded-lg hover:bg-red-50 text-red-500 transition-all"
                      title={isFr ? "Supprimer" : "Delete"}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      {/* ── Add Modal ────────────────────────────────────────────────── */}
      <Modal
        open={addOpen}
        onClose={() => setAddOpen(false)}
        title={isFr ? "Ajouter un agent" : "Add agent"}
      >
        <div className="space-y-4">
          <InputField
            label={isFr ? "Nom complet *" : "Full name *"}
            value={form.name}
            onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
            placeholder={isFr ? "Jean-Marie Mbarga" : "Jean-Marie Mbarga"}
            required
          />
          <InputField
            label={isFr ? "Téléphone *" : "Phone *"}
            value={form.phone}
            onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
            placeholder="+237 6xx xx xx xx"
            required
          />
          <InputField
            label={isFr ? "Zone de livraison *" : "Delivery zone *"}
            value={form.zone}
            onChange={e => setForm(f => ({ ...f, zone: e.target.value }))}
            placeholder={isFr ? "Akwa, Douala" : "Akwa, Douala"}
            required
          />
          <InputField
            label={isFr ? "Email (optionnel)" : "Email (optional)"}
            type="email"
            value={form.email}
            onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
            placeholder="agent@example.com"
          />
          <div className="flex gap-3 pt-2">
            <PrimaryButton onClick={handleSave} className="flex-1 justify-center" disabled={saving}>
              {saving ? (isFr ? "Enregistrement..." : "Saving...") : (isFr ? "Ajouter" : "Add")}
            </PrimaryButton>
            <SecondaryButton onClick={() => setAddOpen(false)} className="flex-1 justify-center">
              {isFr ? "Annuler" : "Cancel"}
            </SecondaryButton>
          </div>
        </div>
      </Modal>

      {/* ── Edit Modal ───────────────────────────────────────────────── */}
      <Modal
        open={!!editTarget}
        onClose={() => setEditTarget(null)}
        title={isFr ? `Modifier — ${editTarget?.name}` : `Edit — ${editTarget?.name}`}
      >
        <div className="space-y-4">
          <InputField
            label={isFr ? "Nom complet *" : "Full name *"}
            value={form.name}
            onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
            required
          />
          <InputField
            label={isFr ? "Téléphone *" : "Phone *"}
            value={form.phone}
            onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
            required
          />
          <InputField
            label={isFr ? "Zone de livraison *" : "Delivery zone *"}
            value={form.zone}
            onChange={e => setForm(f => ({ ...f, zone: e.target.value }))}
            required
          />
          <InputField
            label="Email"
            type="email"
            value={form.email}
            onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
          />
          <div className="flex gap-3 pt-2">
            <PrimaryButton onClick={handleSave} className="flex-1 justify-center" disabled={saving}>
              {saving ? (isFr ? "Enregistrement..." : "Saving...") : (isFr ? "Enregistrer" : "Save")}
            </PrimaryButton>
            <SecondaryButton onClick={() => setEditTarget(null)} className="flex-1 justify-center">
              {isFr ? "Annuler" : "Cancel"}
            </SecondaryButton>
          </div>
        </div>
      </Modal>

      {/* ── Delete Confirm Modal ─────────────────────────────────────── */}
      <Modal
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        title={isFr ? "Confirmer la suppression" : "Confirm deletion"}
        width="max-w-sm"
      >
        <div className="text-center space-y-4">
          <div className="w-14 h-14 rounded-full bg-red-50 flex items-center justify-center mx-auto">
            <AlertTriangle size={26} className="text-red-500" />
          </div>
          <div>
            <p className="font-semibold font-sora" style={{ color: "#0D3B36" }}>
              {isFr ? "Supprimer cet agent ?" : "Delete this agent?"}
            </p>
            <p className="text-sm text-gray-500 mt-1">
              <span className="font-medium text-gray-700">&ldquo;{deleteTarget?.name}&rdquo;</span>
              {isFr
                ? " sera définitivement retiré de l'équipe de livraison."
                : " will be permanently removed from the delivery team."}
            </p>
          </div>
          <div className="flex gap-3 pt-1">
            <SecondaryButton onClick={() => setDeleteTarget(null)} className="flex-1 justify-center">
              {isFr ? "Annuler" : "Cancel"}
            </SecondaryButton>
            <button
              onClick={handleDelete}
              className="flex-1 py-2.5 rounded-lg text-white font-semibold text-sm bg-red-500 hover:bg-red-600 transition-all active:scale-95"
            >
              {isFr ? "Supprimer" : "Delete"}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
