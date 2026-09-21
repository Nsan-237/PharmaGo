import React, { useState, useEffect } from "react";
import { Search, Download, Plus, Pencil, Trash2, UserCheck, UserX, X, Check } from "lucide-react";
import { users as initialUsers } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { exportToCSV } from "../../utils/exportUtils";
import { apiGetUsers, apiCreateUser, apiUpdateUser, apiDeleteUser } from "../../utils/api";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function PlatformUsers() {
  const t = useT();
  const [users, setUsers] = useState(initialUsers);
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [loading, setLoading] = useState(false);

  // Modals state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);

  // Form states
  const [formData, setFormData] = useState({
    fullName: "",
    email: "",
    password: "",
    phone: "",
    role: "PATIENT",
    isApproved: true,
  });

  const roleLabels = {
    client:           t("users.roleClient") || "Client",
    PATIENT:          t("users.roleClient") || "Client",
    pharmacien:       t("users.rolePharma") || "Pharmacien",
    PHARMACY_ADMIN:   t("users.roleAdminPharma") || "Admin Pharmacie",
    CASHIER:          "Caissier POS",
    agent_livraison:  t("users.roleAgent") || "Agent Livraison",
    DELIVERY_AGENT:   t("users.roleAgent") || "Agent Livraison",
    admin_pharmacie:  t("users.roleAdminPharma") || "Admin Pharmacie",
    admin_plateforme: t("users.roleAdminPlat") || "Super Admin",
    PLATFORM_ADMIN:   t("users.roleAdminPlat") || "Super Admin",
  };

  // ── Fetch Users from Backend ──────────────────────────────────────────────
  const fetchUsers = async () => {
    setLoading(true);
    try {
      const res = await apiGetUsers();
      if (res && res.users && res.users.length > 0) {
        const mapped = res.users.map((u) => ({
          id: u.id,
          name: u.fullName || u.email.split("@")[0],
          email: u.email,
          phone: u.phone || "+237 6xx xx xx xx",
          role: u.role,
          status: u.isApproved ? "actif" : "suspendu",
          joinedAt: new Date(u.createdAt).toISOString().slice(0, 10),
        }));
        setUsers(mapped);
      }
    } catch (err) {
      console.log("Using fallback users list:", err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  // ── Handlers ─────────────────────────────────────────────────────────────
  const handleOpenAdd = () => {
    setFormData({
      fullName: "",
      email: "",
      password: "password123",
      phone: "+237 ",
      role: "PATIENT",
      isApproved: true,
    });
    setIsAddOpen(true);
  };

  const handleCreateUser = async (e) => {
    e.preventDefault();
    try {
      const res = await apiCreateUser({
        fullName: formData.fullName,
        email: formData.email,
        password: formData.password,
        phone: formData.phone,
        role: formData.role,
        isApproved: formData.isApproved,
      });

      const newUser = {
        id: res?.user?.id || `user-${Date.now()}`,
        name: formData.fullName,
        email: formData.email,
        phone: formData.phone,
        role: formData.role,
        status: formData.isApproved ? "actif" : "suspendu",
        joinedAt: new Date().toISOString().slice(0, 10),
      };

      setUsers((prev) => [newUser, ...prev]);
      setIsAddOpen(false);
    } catch (err) {
      alert(err.message || "Erreur lors de la création");
    }
  };

  const handleOpenEdit = (user) => {
    setSelectedUser(user);
    setFormData({
      fullName: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isApproved: user.status === "actif",
    });
    setIsEditOpen(true);
  };

  const handleUpdateUser = async (e) => {
    e.preventDefault();
    if (!selectedUser) return;

    try {
      await apiUpdateUser(selectedUser.id, {
        fullName: formData.fullName,
        phone: formData.phone,
        role: formData.role,
        isApproved: formData.isApproved,
      });

      setUsers((prev) =>
        prev.map((u) =>
          u.id === selectedUser.id
            ? {
                ...u,
                name: formData.fullName,
                phone: formData.phone,
                role: formData.role,
                status: formData.isApproved ? "actif" : "suspendu",
              }
            : u
        )
      );
      setIsEditOpen(false);
    } catch (err) {
      alert(err.message || "Erreur lors de la mise à jour");
    }
  };

  const handleOpenDelete = (user) => {
    setSelectedUser(user);
    setIsDeleteOpen(true);
  };

  const handleDeleteUser = async () => {
    if (!selectedUser) return;
    try {
      await apiDeleteUser(selectedUser.id);
      setUsers((prev) => prev.filter((u) => u.id !== selectedUser.id));
      setIsDeleteOpen(false);
    } catch (err) {
      alert(err.message || "Erreur lors de la suppression");
    }
  };

  const toggleStatus = async (user) => {
    const newStatus = user.status === "actif" ? "suspendu" : "actif";
    try {
      await apiUpdateUser(user.id, { isApproved: newStatus === "actif" });
    } catch (_) {}
    setUsers((prev) =>
      prev.map((u) => (u.id === user.id ? { ...u, status: newStatus } : u))
    );
  };

  // ── Filters ──────────────────────────────────────────────────────────────
  const filtered = users.filter((u) => {
    const q = search.toLowerCase();
    const matchSearch =
      (u.name || "").toLowerCase().includes(q) ||
      (u.email || "").toLowerCase().includes(q) ||
      (u.phone || "").toLowerCase().includes(q);
    const matchRole =
      roleFilter === "all" ||
      u.role.toLowerCase() === roleFilter.toLowerCase() ||
      (roleFilter === "client" && (u.role === "PATIENT" || u.role === "client")) ||
      (roleFilter === "pharmacien" && (u.role === "PHARMACY_ADMIN" || u.role === "pharmacien")) ||
      (roleFilter === "caissier" && u.role === "CASHIER") ||
      (roleFilter === "agent_livraison" && (u.role === "DELIVERY_AGENT" || u.role === "agent_livraison"));
    const matchStatus = statusFilter === "all" || u.status === statusFilter;
    return matchSearch && matchRole && matchStatus;
  });

  const handleExportCSV = () => {
    const headers = [
      t("users.colUser") || "Utilisateur",
      "Email",
      t("users.colRole") || "Rôle",
      t("users.colPhone") || "Téléphone",
      t("users.colJoined") || "Date d'inscription",
      t("users.colStatus") || "Statut",
    ];
    const rows = filtered.map((u) => [
      u.name,
      u.email,
      roleLabels[u.role] || u.role,
      u.phone,
      u.joinedAt,
      t(`status.${u.status}`) || u.status,
    ]);
    exportToCSV(headers, rows, `pharmago_users_${new Date().toISOString().slice(0, 10)}`);
  };

  return (
    <div>
      <PageHeader
        title={t("users.title") || "Gestion des Utilisateurs"}
        subtitle={`${users.length} ${t("users.subtitle") || "utilisateurs enregistrés"}`}
        action={
          <div className="flex items-center gap-2">
            <button
              onClick={handleOpenAdd}
              className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-white text-sm font-bold shadow-md hover:opacity-95 transition-all cursor-pointer"
              style={{ background: "#0F9B8E" }}
            >
              <Plus size={16} />
              <span>Nouvel utilisateur</span>
            </button>
            <button
              onClick={handleExportCSV}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl border text-sm font-medium hover:bg-gray-50 transition-colors bg-white shadow-xs cursor-pointer"
              style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
            >
              <Download size={14} /> {t("export.csv") || "Exporter"}
            </button>
          </div>
        }
      />

      <Card>
        {/* Filters bar */}
        <div
          className="p-4 border-b flex flex-col sm:flex-row items-start sm:items-center gap-3"
          style={{ borderColor: "#DCE6E2" }}
        >
          <div className="relative flex-1 max-w-sm w-full">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              placeholder={t("users.searchPh") || "Rechercher par nom, email ou téléphone..."}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-3 py-2 rounded-xl border text-sm outline-none"
              style={{ borderColor: "#DCE6E2", background: "#F6F5EF" }}
            />
          </div>

          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="px-3 py-2 rounded-xl border text-sm outline-none bg-white"
            style={{ borderColor: "#DCE6E2" }}
          >
            <option value="all">Tous les rôles</option>
            <option value="client">Client (Patient)</option>
            <option value="pharmacien">Pharmacien Admin</option>
            <option value="caissier">Caissier POS</option>
            <option value="agent_livraison">Agent de Livraison</option>
            <option value="PLATFORM_ADMIN">Super Admin</option>
          </select>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 rounded-xl border text-sm outline-none bg-white"
            style={{ borderColor: "#DCE6E2" }}
          >
            <option value="all">{t("filter.allStatuses") || "Tous les statuts"}</option>
            <option value="actif">{t("status.actif") || "Actif"}</option>
            <option value="suspendu">{t("status.suspendu") || "Suspendu"}</option>
          </select>
        </div>

        {/* Table */}
        <TableWrapper>
          <thead>
            <tr>
              <Th>{t("users.colUser") || "Utilisateur"}</Th>
              <Th>{t("users.colRole") || "Rôle"}</Th>
              <Th>{t("users.colPhone") || "Téléphone"}</Th>
              <Th>{t("users.colJoined") || "Inscrit le"}</Th>
              <Th>{t("users.colStatus") || "Statut"}</Th>
              <Th className="text-right">Actions</Th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((u) => (
              <tr key={u.id} className="hover:bg-gray-50 transition-colors">
                <Td>
                  <div className="flex items-center gap-3">
                    <div
                      className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0"
                      style={{ background: "#0F9B8E" }}
                    >
                      {(u.name || "U")
                        .split(" ")
                        .map((n) => n[0])
                        .join("")
                        .slice(0, 2)
                        .toUpperCase()}
                    </div>
                    <div>
                      <p className="font-semibold text-sm leading-tight" style={{ color: "#0D3B36" }}>
                        {u.name}
                      </p>
                      <p className="text-xs text-gray-400">{u.email}</p>
                    </div>
                  </div>
                </Td>
                <Td>
                  <span className="text-xs font-medium px-2.5 py-1 bg-gray-100 rounded-full text-gray-700">
                    {roleLabels[u.role] || u.role}
                  </span>
                </Td>
                <Td>
                  <span className="text-sm text-gray-600">{u.phone}</span>
                </Td>
                <Td>
                  <span className="text-xs text-gray-400">{u.joinedAt}</span>
                </Td>
                <Td>
                  <StatusBadge status={u.status} />
                </Td>
                <Td className="text-right">
                  <div className="flex items-center justify-end gap-1.5">
                    {/* Toggle status */}
                    <button
                      onClick={() => toggleStatus(u)}
                      title={u.status === "actif" ? "Suspendre" : "Réactiver"}
                      className={`p-1.5 rounded-lg text-xs font-medium transition-colors cursor-pointer ${
                        u.status === "actif"
                          ? "hover:bg-amber-50 text-amber-600"
                          : "hover:bg-emerald-50 text-emerald-600"
                      }`}
                    >
                      {u.status === "actif" ? <UserX size={15} /> : <UserCheck size={15} />}
                    </button>

                    {/* Edit */}
                    <button
                      onClick={() => handleOpenEdit(u)}
                      title="Modifier"
                      className="p-1.5 rounded-lg text-gray-500 hover:text-[#0F9B8E] hover:bg-emerald-50 transition-colors cursor-pointer"
                    >
                      <Pencil size={15} />
                    </button>

                    {/* Delete */}
                    <button
                      onClick={() => handleOpenDelete(u)}
                      title="Supprimer"
                      className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer"
                    >
                      <Trash2 size={15} />
                    </button>
                  </div>
                </Td>
              </tr>
            ))}

            {filtered.length === 0 && (
              <tr>
                <td colSpan={6} className="text-center py-10 text-gray-400 text-sm">
                  {loading ? "Chargement des utilisateurs..." : "Aucun utilisateur trouvé."}
                </td>
              </tr>
            )}
          </tbody>
        </TableWrapper>
      </Card>

      {/* ── Modal: Create User ──────────────────────────────────────────────── */}
      {isAddOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-gray-100">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100 mb-5">
              <h3 className="text-lg font-bold font-sora" style={{ color: "#0D3B36" }}>
                Créer un utilisateur
              </h3>
              <button
                onClick={() => setIsAddOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-600"
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateUser} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Nom complet *</label>
                <input
                  type="text"
                  required
                  value={formData.fullName}
                  onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                  placeholder="ex: Dr. Samuel Eto'o"
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Email *</label>
                <input
                  type="email"
                  required
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  placeholder="nom@domaine.cm"
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Mot de passe temporaire *</label>
                <input
                  type="text"
                  required
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  placeholder="Min 6 caractères"
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Téléphone</label>
                <input
                  type="text"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  placeholder="+237 6xx xx xx xx"
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Rôle</label>
                <select
                  value={formData.role}
                  onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none bg-white"
                  style={{ borderColor: "#DCE6E2" }}
                >
                  <option value="PATIENT">Client (Patient)</option>
                  <option value="PHARMACY_ADMIN">Pharmacien Administrateur</option>
                  <option value="CASHIER">Caissier POS</option>
                  <option value="DELIVERY_AGENT">Agent de Livraison</option>
                  <option value="PLATFORM_ADMIN">Super Admin Plateforme</option>
                </select>
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
                  Créer le compte
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Modal: Edit User ────────────────────────────────────────────────── */}
      {isEditOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-gray-100">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100 mb-5">
              <h3 className="text-lg font-bold font-sora" style={{ color: "#0D3B36" }}>
                Modifier l'utilisateur
              </h3>
              <button
                onClick={() => setIsEditOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-600"
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleUpdateUser} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Nom complet</label>
                <input
                  type="text"
                  required
                  value={formData.fullName}
                  onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Email (non modifiable)</label>
                <input
                  type="text"
                  disabled
                  value={formData.email}
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none bg-gray-50 text-gray-500"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Téléphone</label>
                <input
                  type="text"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none focus:border-[#0F9B8E]"
                  style={{ borderColor: "#DCE6E2" }}
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Rôle</label>
                <select
                  value={formData.role}
                  onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border text-sm outline-none bg-white"
                  style={{ borderColor: "#DCE6E2" }}
                >
                  <option value="PATIENT">Client (Patient)</option>
                  <option value="PHARMACY_ADMIN">Pharmacien Administrateur</option>
                  <option value="CASHIER">Caissier POS</option>
                  <option value="DELIVERY_AGENT">Agent de Livraison</option>
                  <option value="PLATFORM_ADMIN">Super Admin Plateforme</option>
                </select>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <input
                  type="checkbox"
                  id="editIsApproved"
                  checked={formData.isApproved}
                  onChange={(e) => setFormData({ ...formData, isApproved: e.target.checked })}
                  className="w-4 h-4 rounded text-[#0F9B8E] focus:ring-[#0F9B8E]"
                />
                <label htmlFor="editIsApproved" className="text-xs font-medium text-gray-700">
                  Compte actif et approuvé
                </label>
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

      {/* ── Modal: Delete Confirmation ────────────────────────────────────── */}
      {isDeleteOpen && selectedUser && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white rounded-3xl max-w-sm w-full p-6 shadow-2xl border border-gray-100 text-center">
            <div className="w-12 h-12 rounded-2xl bg-red-100 text-red-600 flex items-center justify-center mx-auto mb-4">
              <Trash2 size={24} />
            </div>
            <h3 className="text-lg font-bold font-sora mb-2" style={{ color: "#0D3B36" }}>
              Supprimer l'utilisateur ?
            </h3>
            <p className="text-xs text-gray-500 mb-6">
              Êtes-vous sûr de vouloir supprimer définitivement le compte de{" "}
              <strong className="text-gray-800">{selectedUser.name}</strong> ({selectedUser.email}) ? Cette action est irréversible.
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
                onClick={handleDeleteUser}
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
