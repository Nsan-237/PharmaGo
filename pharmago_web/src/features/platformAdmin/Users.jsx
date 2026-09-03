import React, { useState } from "react";
import { Search, Download } from "lucide-react";
import { users as initialUsers } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { exportToCSV } from "../../utils/exportUtils";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function PlatformUsers() {
  const t = useT();
  const [users, setUsers] = useState(initialUsers);
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");

  const roleLabels = {
    client:          t("users.roleClient"),
    pharmacien:      t("users.rolePharma"),
    agent_livraison: t("users.roleAgent"),
    admin_pharmacie: t("users.roleAdminPharma"),
    admin_plateforme:t("users.roleAdminPlat"),
  };

  const toggleStatus = (id) => setUsers(prev => prev.map(u => u.id===id ? {...u, status: u.status==="actif" ? "suspendu" : "actif"} : u));

  const filtered = users.filter(u => {
    const matchSearch = u.name.toLowerCase().includes(search.toLowerCase()) || u.email.toLowerCase().includes(search.toLowerCase());
    const matchRole   = roleFilter === "all" || u.role === roleFilter;
    const matchStatus = statusFilter === "all" || u.status === statusFilter;
    return matchSearch && matchRole && matchStatus;
  });

  const roles = ["all","client","pharmacien","agent_livraison","admin_pharmacie"];

  const handleExportCSV = () => {
    const headers = [t("users.colUser"), "Email", t("users.colRole"), t("users.colPhone"), t("users.colJoined"), t("users.colStatus")];
    const rows = filtered.map(u => [u.name, u.email, roleLabels[u.role] || u.role, u.phone, u.joinedAt, t(`status.${u.status}`)]);
    exportToCSV(headers, rows, `pharmago_users_${new Date().toISOString().slice(0,10)}`);
  };

  return (
    <div>
      <PageHeader
        title={t("users.title")}
        subtitle={`${users.length} ${t("users.subtitle")}`}
        action={
          <button
            onClick={handleExportCSV}
            className="flex items-center gap-1.5 px-3 py-2 rounded-lg border text-sm font-medium hover:bg-gray-50 transition-colors bg-white shadow-xs"
            style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
          >
            <Download size={14} /> {t("export.csv")}
          </button>
        }
      />
      <Card>
        <div className="p-4 border-b flex flex-col sm:flex-row items-start sm:items-center gap-3" style={{ borderColor: "#DCE6E2" }}>
          <div className="relative flex-1 max-w-sm w-full">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input placeholder={t("users.searchPh")} value={search} onChange={e=>setSearch(e.target.value)}
              className="w-full pl-9 pr-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2", background: "#F6F5EF" }} />
          </div>
          <select value={roleFilter} onChange={e=>setRoleFilter(e.target.value)}
            className="px-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2" }}>
            <option value="all">{t("users.allRoles")}</option>
            {roles.slice(1).map(r => <option key={r} value={r}>{roleLabels[r]}</option>)}
          </select>
          <select value={statusFilter} onChange={e=>setStatusFilter(e.target.value)}
            className="px-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2" }}>
            <option value="all">{t("filter.allStatuses")}</option>
            <option value="actif">{t("status.actif")}</option>
            <option value="suspendu">{t("status.suspendu")}</option>
          </select>
        </div>
        <TableWrapper>
          <thead>
            <tr>
              <Th>{t("users.colUser")}</Th>
              <Th>{t("users.colRole")}</Th>
              <Th>{t("users.colPhone")}</Th>
              <Th>{t("users.colJoined")}</Th>
              <Th>{t("users.colStatus")}</Th>
              <Th>{t("users.colAction")}</Th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(u => (
              <tr key={u.id} className="hover:bg-gray-50">
                <Td>
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold" style={{ background: "#0F9B8E" }}>
                      {u.name.split(" ").map(n=>n[0]).join("").slice(0,2)}
                    </div>
                    <div>
                      <p className="font-medium" style={{ color: "#0D3B36" }}>{u.name}</p>
                      <p className="text-xs text-gray-400">{u.email}</p>
                    </div>
                  </div>
                </Td>
                <Td><span className="text-xs px-2 py-0.5 bg-gray-100 rounded-full text-gray-600">{roleLabels[u.role]||u.role}</span></Td>
                <Td><span className="text-sm text-gray-600">{u.phone}</span></Td>
                <Td><span className="text-xs text-gray-400">{u.joinedAt}</span></Td>
                <Td><StatusBadge status={u.status} /></Td>
                <Td>
                  <button onClick={() => toggleStatus(u.id)}
                    className={`text-xs px-3 py-1.5 rounded-lg font-medium transition-all ${u.status==="actif" ? "bg-red-50 text-red-600 hover:bg-red-100" : "bg-green-50 text-green-600 hover:bg-green-100"}`}>
                    {u.status==="actif" ? t("common.suspend") : t("common.reactivate")}
                  </button>
                </Td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={6} className="text-center py-8 text-gray-400 text-sm">{t("common.noData")}</td></tr>
            )}
          </tbody>
        </TableWrapper>
      </Card>
    </div>
  );
}
