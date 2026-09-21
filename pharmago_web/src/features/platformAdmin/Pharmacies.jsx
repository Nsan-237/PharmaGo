import React, { useState, useEffect } from "react";
import { Plus, Pencil, Trash2, CheckCircle, XCircle, Phone, MapPin, Search, Download, Clock, Shield, X } from "lucide-react";
import { pharmacies as initialPharmacies } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { exportToCSV } from "../../utils/exportUtils";
import { apiGetPharmacies, apiCreatePharmacy, apiUpdatePharmacyFull, apiDeletePharmacy, apiApprovePharmacy } from "../../utils/api";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function PlatformPharmacies() {
  const t = useT();
  const [pharmacies, setPharmacies] = useState(initialPharmacies);
  const [search, setSearch] = useState("");
  const [cityFilter, setCityFilter] = useState("all");
  const [guardFilter, setGuardFilter] = useState("all");
  const [loading, setLoading] = useState(false);

  // Modal states
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [selectedPharma, setSelectedPharma] = useState(null);

  // Form data
  const [formData, setFormData] = useState({
    name: "",
    city: "Douala",
    quarter: "",
    address: "",
    phone: "+237 ",
    email: "",
    openingHours: "08:00 - 20:00",
    isGuard247: false,
    isApproved: true,
  });

  const cities = ["Douala", "Yaoundé", "Bafoussam", "Garoua", "Bamenda", "Kribi", "Buea", "Limbe"];

  // ── Fetch Pharmacies from Backend ─────────────────────────────────────────
  const fetchPharmacies = async () => {
    setLoading(true);
    try {
      const res = await apiGetPharmacies();
      if (res && res.pharmacies && res.pharmacies.length > 0) {
        const mapped = res.pharmacies.map((p) => ({
          id: p.id,
          name: p.name,
          address: p.address,
          city: p.city,
          quarter: p.quarter || "",
          phone: p.phone,
          email: p.email || "",
          openingHours: p.openingHours || "08:00 - 20:00",
          isGuard247: Boolean(p.isGuard247),
          approved: Boolean(p.isApproved),
          status: p.isApproved ? "active" : "pending",
          orders: p._count?.orders || 0,
          revenue: (p._count?.orders || 0) * 12500,
        }));
        setPharmacies(mapped);
      }
    } catch (err) {
      console.log("Using fallback pharmacies list:", err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPharmacies();
  }, []);

  // ── Handlers ─────────────────────────────────────────────────────────────
  const handleOpenAdd = () => {
    setFormData({
      name: "",
      city: "Douala",
      quarter: "",
      address: "",
      phone: "+237 ",
      email: "",
      openingHours: "08:00 - 20:00",
      isGuard247: false,
      isApproved: true,
    });
    setIsAddOpen(true);
  };

  const handleCreatePharmacy = async (e) => {
    e.preventDefault();
    try {
      const res = await apiCreatePharmacy(formData);
      const created = res?.pharmacy || {};

      const newEntry = {
        id: created.id || `pharm-${Date.now()}`,
        name: formData.name,
        address: formData.address,
        city: formData.city,
        quarter: formData.quarter,
        phone: formData.phone,
        email: formData.email,
        openingHours: formData.openingHours,
        isGuard247: formData.isGuard247,
        approved: formData.isApproved,
        status: formData.isApproved ? "active" : "pending",
        orders: 0,
        revenue: 0,
      };

      setPharmacies((prev) => [newEntry, ...prev]);
      setIsAddOpen(false);
    } catch (err) {
      alert(err.message || "Erreur lors de l'ajout de la pharmacie");
    }
  };

  const handleOpenEdit = (p) => {
    setSelectedPharma(p);
    setFormData({
      name: p.name,
      city: p.city,
      quarter: p.quarter || "",
      address: p.address,
      phone: p.phone,
      email: p.email || "",
      openingHours: p.openingHours || "08:00 - 20:00",
      isGuard247: Boolean(p.isGuard247),
      isApproved: Boolean(p.approved),
    });
    setIsEditOpen(true);
  };

  const handleUpdatePharmacy = async (e) => {
    e.preventDefault();
    if (!selectedPharma) return;

    try {
      await apiUpdatePharmacyFull(selectedPharma.id, formData);

      setPharmacies((prev) =>
        prev.map((p) =>
          p.id === selectedPharma.id
            ? {
                ...p,
                name: formData.name,
                city: formData.city,
                quarter: formData.quarter,
                address: formData.address,
                phone: formData.phone,
                email: formData.email,
                openingHours: formData.openingHours,
                isGuard247: formData.isGuard247,
                approved: formData.isApproved,
                status: formData.isApproved ? "active" : "pending",
              }
            : p
        )
      );
      setIsEditOpen(false);
    } catch (err) {
      alert(err.message || "Erreur lors de la mise à jour");
    }
  };

  const handleOpenDelete = (p) => {
    setSelectedPharma(p);
    setIsDeleteOpen(true);
  };

  const handleDeletePharmacy = async () => {
    if (!selectedPharma) return;
    try {
      await apiDeletePharmacy(selectedPharma.id);
      setPharmacies((prev) => prev.filter((p) => p.id !== selectedPharma.id));
      setIsDeleteOpen(false);
    } catch (err) {
      alert(err.message || "Erreur lors de la suppression");
    }
  };

  const approve = async (id) => {
    try {
      await apiApprovePharmacy(id, true);
    } catch (_) {}
    setPharmacies((prev) =>
      prev.map((p) => (p.id === id ? { ...p, approved: true, status: "active" } : p))
    );
  };

  const toggleSuspend = async (id) => {
    const pharma = pharmacies.find((p) => p.id === id);
    if (!pharma) return;
    const newStatus = pharma.status === "active" ? "suspended" : "active";
    try {
      await apiUpdatePharmacyFull(id, { isApproved: newStatus === "active" });
    } catch (_) {}
    setPharmacies((prev) =>
      prev.map((p) => (p.id === id ? { ...p, status: newStatus, approved: newStatus === "active" } : p))
    );
  };

  // ── Filters ──────────────────────────────────────────────────────────────
  const filtered = pharmacies.filter((p) => {
    const q = search.toLowerCase();
    const matchSearch =
      (p.name || "").toLowerCase().includes(q) ||
      (p.address || "").toLowerCase().includes(q) ||
      (p.city || "").toLowerCase().includes(q) ||
      (p.quarter || "").toLowerCase().includes(q);
    const matchCity = cityFilter === "all" || p.city === cityFilter;
    const matchGuard =
      guardFilter === "all" ||
      (guardFilter === "guard" && p.isGuard247) ||
      (guardFilter === "standard" && !p.isGuard247);
    return matchSearch && matchCity && matchGuard;
  });

  const pending = filtered.filter((p) => !p.approved);
  const active = filtered.filter((p) => p.approved);

  const handleExportCSV = () => {
    const headers = ["Pharmacie", "Ville", "Quartier", "Téléphone", "Garde 24/7", "Commandes", "Statut"];
    const rows = filtered.map((p) => [
      p.name,
      p.city,
      p.quarter || "-",
      p.phone,
      p.isGuard247 ? "Oui" : "Non",
      p.orders,
      p.status,
    ]);
    exportToCSV(headers, rows, `pharmago_pharmacies_${new Date().toISOString().slice(0, 10)}`);
  };

  return (
    <div>
      <PageHeader
        title={t("pharmacies.title") || "Gestion des Pharmacies"}
        subtitle={`${pharmacies.length} pharmacies enregistrées · ${pending.length} en attente`}
        action={
          <div className="flex items-center gap-2">
            <button
              onClick={handleOpenAdd}
              className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-white text-sm font-bold shadow-md hover:opacity-95 transition-all cursor-pointer"
              style={{ background: "#0F9B8E" }}
            >
              <Plus size={16} />
              <span>Ajouter une pharmacie</span>
            </button>
            <button
              onClick={handleExportCSV}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl border text-sm font-medium hover:bg-gray-50 transition-colors bg-white shadow-xs cursor-pointer"
              style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
            >
              <Download size={14} /> Exporter
            </button>
          </div>
        }
      />

      {/* Pending Approvals alert banner */}
      {pending.length > 0 && (
        <div className="mb-6">
          <h2 className="font-semibold font-sora mb-3 flex items-center gap-2" style={{ color: "#0D3B36" }}>
            <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-pulse" />
            Demandes d'adhésion en attente ({pending.length})
          </h2>
          <div className="space-y-3">
            {pending.map((p) => (
              <div
                key={p.id}
                className="bg-white rounded-2xl border p-4 flex flex-col sm:flex-row items-start sm:items-center gap-4 shadow-xs"
                style={{ borderColor: "#E8A33D", borderLeftWidth: 5 }}
              >
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <p className="font-bold font-sora" style={{ color: "#0D3B36" }}>
                      {p.name}
                    </p>
                    {p.isGuard247 && (
                      <span className="text-[10px] font-bold px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded-full">
                        24h/24
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-gray-500 flex items-center gap-1 mt-1">
                    <MapPin size={13} className="text-[#0F9B8E]" /> {p.address} ({p.city})
                  </p>
                  <p className="text-xs text-gray-500 flex items-center gap-1 mt-0.5">
                    <Phone size={13} className="text-gray-400" /> {p.phone}
                  </p>
                </div>
                <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
                  <button
                    onClick={() => approve(p.id)}
                    className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-white text-xs font-bold shadow-xs cursor-pointer hover:opacity-95"
                    style={{ background: "#0F9B8E" }}
                  >
                    <CheckCircle size={14} /> Approuver
                  </button>
                  <button
                    onClick={() => handleOpenDelete(p)}
                    className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-white text-xs font-bold bg-red-500 hover:bg-red-600 shadow-xs cursor-pointer"
                  >
                    <XCircle size={14} /> Refuser
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Main Table Card */}
      <Card>
        {/* Filters */}
        <div
          className="p-4 border-b flex flex-col sm:flex-row items-start sm:items-center gap-3"
          style={{ borderColor: "#DCE6E2" }}
        >
          <div className="relative flex-1 max-w-sm w-full">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              placeholder="Rechercher par nom, ville, quartier..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-3 py-2 rounded-xl border text-sm outline-none"
              style={{ borderColor: "#DCE6E2", background: "#F6F5EF" }}
            />
          </div>

          <select
            value={cityFilter}
            onChange={(e) => setCityFilter(e.target.value)}
            className="px-3 py-2 rounded-xl border text-sm outline-none bg-white"
            style={{ borderColor: "#DCE6E2" }}
          >
            <option value="all">Toutes les villes</option>
            {cities.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>

          <select
            value={guardFilter}
            onChange={(e) => setGuardFilter(e.target.value)}
            className="px-3 py-2 rounded-xl border text-sm outline-none bg-white"
            style={{ borderColor: "#DCE6E2" }}
          >
            <option value="all">Tous les horaires</option>
            <option value="guard">Pharmacie de garde 24/7</option>
            <option value="standard">Horaires normaux</option>
          </select>
        </div>

        {/* Table */}
        <TableWrapper>
          <thead>
            <tr>
              <Th>Pharmacie</Th>
              <Th>Ville / Quartier</Th>
              <Th>Téléphone</Th>
              <Th>Horaires</Th>
              <Th>Commandes</Th>
              <Th>Statut</Th>
              <Th className="text-right">Actions</Th>
            </tr>
          </thead>
          <tbody>
            {active.map((p) => (
              <tr key={p.id} className="hover:bg-gray-50 transition-colors">
                <Td>
                  <div>
                    <p className="font-semibold text-sm leading-tight" style={{ color: "#0D3B36" }}>
                      {p.name}
                    </p>
                    <p className="text-xs text-gray-400">{p.address}</p>
                  </div>
                </Td>
                <Td>
                  <span className="text-sm font-medium text-gray-800">{p.city}</span>
                  {p.quarter && <p className="text-xs text-gray-400">{p.quarter}</p>}
                </Td>
                <Td>
                  <span className="text-sm text-gray-600">{p.phone}</span>
                </Td>
                <Td>
                  {p.isGuard247 ? (
                    <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full">
                      <Clock size={12} /> 24h / 24
                    </span>
                  ) : (
                    <span className="text-xs text-gray-600">{p.openingHours}</span>
                  )}
                </Td>
                <Td>
                  <span className="font-bold text-sm text-gray-800">{p.orders}</span>
                </Td>
                <Td>
                  <StatusBadge status={p.status} />
                </Td>
                <Td className="text-right">
                  <div className="flex items-center justify-end gap-1.5">
                    {/* Toggle suspend */}
                    <button
                      onClick={() => toggleSuspend(p.id)}
                      title={p.status === "active" ? "Suspendre" : "Réactiver"}
                      className={`text-xs px-2.5 py-1.5 rounded-lg font-medium transition-colors cursor-pointer ${
                        p.status === "active"
                          ? "bg-amber-50 text-amber-600 hover:bg-amber-100"
                          : "bg-green-50 text-green-600 hover:bg-green-100"
                      }`}
                    >
                      {p.status === "active" ? "Suspendre" : "Réactiver"}
                    </button>

                    {/* Edit */}
                    <button
                      onClick={() => handleOpenEdit(p)}
                      title="Modifier"
                      className="p-1.5 rounded-lg text-gray-500 hover:text-[#0F9B8E] hover:bg-emerald-50 transition-colors cursor-pointer"
                    >
                      <Pencil size={15} />
                    </button>

                    {/* Delete */}
                    <button
                      onClick={() => handleOpenDelete(p)}
                      title="Supprimer"
                      className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer"
                    >
                      <Trash2 size={15} />
                    </button>
                  </div>
                </Td>
              </tr>
            ))}

            {active.length === 0 && (
              <tr>
                <td colSpan={7} className="text-center py-10 text-gray-400 text-sm">
                  {loading ? "Chargement des pharmacies..." : "Aucune pharmacie trouvée."}
                </td>
              </tr>
            )}
          </tbody>
        </TableWrapper>
      </Card>

      {/* ── Modal: Add Pharmacy ─────────────────────────────────────────────── */}
      {isAddOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-gray-100 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100 mb-5">
              <h3 className="text-lg font-bold font-sora" style={{ color: "#0D3B36" }}>
                Ajouter une nouvelle pharmacie
              </h3>
              <button
                onClick={() => setIsAddOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-600"
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreatePharmacy} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Nom de la pharmacie *</label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="ex: Pharmacie du Rond-Point"
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Ville *</label>
                  <select
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none bg-white"
                    style={{ borderColor: "#DCE6E2" }}
                  >
                    {cities.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Quartier</label>
                  <input
                    type="text"
                    value={formData.quarter}
                    onChange={(e) => setFormData({ ...formData, quarter: e.target.value })}
                    placeholder="ex: Akwa, Bonanjo..."
                    className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                    style={{ borderColor: "#DCE6E2" }}
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Adresse détaillée *</label>
                <input
                  type="text"
                  required
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  placeholder="ex: Rue Deido, face Total Energy"
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Téléphone *</label>
                  <input
                    type="text"
                    required
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    placeholder="+237 233 xx xx xx"
                    className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                    style={{ borderColor: "#DCE6E2" }}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Email</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder="contact@pharmacie.cm"
                    className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                    style={{ borderColor: "#DCE6E2" }}
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Horaires d'ouverture</label>
                <input
                  type="text"
                  value={formData.openingHours}
                  onChange={(e) => setFormData({ ...formData, openingHours: e.target.value })}
                  placeholder="ex: 08:00 - 21:00 ou 24h/24"
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div className="p-3 bg-gray-50 rounded-xl space-y-2">
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="addIsGuard"
                    checked={formData.isGuard247}
                    onChange={(e) => setFormData({ ...formData, isGuard247: e.target.checked })}
                    className="w-4 h-4 rounded text-[#0F9B8E] focus:ring-[#0F9B8E]"
                  />
                  <label htmlFor="addIsGuard" className="text-xs font-bold text-gray-800">
                    Pharmacie de garde (Service de Nuit 24h/24)
                  </label>
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="addIsApproved"
                    checked={formData.isApproved}
                    onChange={(e) => setFormData({ ...formData, isApproved: e.target.checked })}
                    className="w-4 h-4 rounded text-[#0F9B8E] focus:ring-[#0F9B8E]"
                  />
                  <label htmlFor="addIsApproved" className="text-xs font-medium text-gray-700">
                    Approuvée et active immédiatement
                  </label>
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setIsAddOpen(false)}
                  className="px-4 py-2.5 rounded-xl border text-sm font-semibold text-gray-600 hover:bg-gray-50"
                  style={{ borderColor: "#DCE6E2" }}
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl text-white text-sm font-bold shadow-md hover:opacity-95"
                  style={{ background: "#0F9B8E" }}
                >
                  Enregistrer la pharmacie
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Modal: Edit Pharmacy ────────────────────────────────────────────── */}
      {isEditOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-gray-100 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100 mb-5">
              <h3 className="text-lg font-bold font-sora" style={{ color: "#0D3B36" }}>
                Modifier la pharmacie
              </h3>
              <button
                onClick={() => setIsEditOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-600"
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleUpdatePharmacy} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Nom</label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Ville</label>
                  <select
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none bg-white"
                    style={{ borderColor: "#DCE6E2" }}
                  >
                    {cities.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Quartier</label>
                  <input
                    type="text"
                    value={formData.quarter}
                    onChange={(e) => setFormData({ ...formData, quarter: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                    style={{ borderColor: "#DCE6E2" }}
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Adresse</label>
                <input
                  type="text"
                  required
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Téléphone</label>
                  <input
                    type="text"
                    required
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                    style={{ borderColor: "#DCE6E2" }}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Email</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                    style={{ borderColor: "#DCE6E2" }}
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Horaires</label>
                <input
                  type="text"
                  value={formData.openingHours}
                  onChange={(e) => setFormData({ ...formData, openingHours: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div className="p-3 bg-gray-50 rounded-xl space-y-2">
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="editIsGuard"
                    checked={formData.isGuard247}
                    onChange={(e) => setFormData({ ...formData, isGuard247: e.target.checked })}
                    className="w-4 h-4 rounded text-[#0F9B8E] focus:ring-[#0F9B8E]"
                  />
                  <label htmlFor="editIsGuard" className="text-xs font-bold text-gray-800">
                    Pharmacie de garde 24h/24
                  </label>
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="editIsApproved"
                    checked={formData.isApproved}
                    onChange={(e) => setFormData({ ...formData, isApproved: e.target.checked })}
                    className="w-4 h-4 rounded text-[#0F9B8E] focus:ring-[#0F9B8E]"
                  />
                  <label htmlFor="editIsApproved" className="text-xs font-medium text-gray-700">
                    Approuvée et active
                  </label>
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setIsEditOpen(false)}
                  className="px-4 py-2.5 rounded-xl border text-sm font-semibold text-gray-600 hover:bg-gray-50"
                  style={{ borderColor: "#DCE6E2" }}
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl text-white text-sm font-bold shadow-md hover:opacity-95"
                  style={{ background: "#0F9B8E" }}
                >
                  Sauvegarder
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Modal: Delete Pharmacy ──────────────────────────────────────────── */}
      {isDeleteOpen && selectedPharma && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white rounded-3xl max-w-sm w-full p-6 shadow-2xl border border-gray-100 text-center">
            <div className="w-12 h-12 rounded-2xl bg-red-100 text-red-600 flex items-center justify-center mx-auto mb-4">
              <Trash2 size={24} />
            </div>
            <h3 className="text-lg font-bold font-sora mb-2" style={{ color: "#0D3B36" }}>
              Supprimer la pharmacie ?
            </h3>
            <p className="text-xs text-gray-500 mb-6">
              Êtes-vous sûr de vouloir supprimer définitivement{" "}
              <strong className="text-gray-800">{selectedPharma.name}</strong> ? Tous les stocks et relations associés seront supprimés.
            </p>
            <div className="flex items-center justify-center gap-3">
              <button
                type="button"
                onClick={() => setIsDeleteOpen(false)}
                className="px-4 py-2.5 rounded-xl border text-sm font-semibold text-gray-600 hover:bg-gray-50 flex-1"
                style={{ borderColor: "#DCE6E2" }}
              >
                Annuler
              </button>
              <button
                type="button"
                onClick={handleDeletePharmacy}
                className="px-4 py-2.5 rounded-xl text-white text-sm font-bold bg-red-600 hover:bg-red-700 shadow-md flex-1 cursor-pointer"
              >
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
