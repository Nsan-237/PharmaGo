import React, { useState } from "react";
import { Outlet, NavLink, useNavigate } from "react-router-dom";
import { useRole } from "../../App";
import { useT, useLang } from "../../i18n/TranslationContext";
import NotificationPanel, { mockNotifications } from "./NotificationPanel";
import {
  LayoutDashboard, Package, ShoppingBag, Users, Clock, Settings,
  ClipboardCheck, FileText, History, Truck, BarChart2, Building2,
  AlertTriangle, ChevronDown, Menu, X, Bell, LogOut, MessageSquare
} from "lucide-react";

const roleColorMap = {
  pharmacy_admin: "bg-primary",
  cashier:        "bg-purple-600",
  delivery_agent: "bg-orange-600",
  platform_admin: "bg-indigo-600",
};

// Nav config uses translation keys, resolved at render time
const roleNavKeys = {
  pharmacy_admin: [
    { icon: LayoutDashboard, key: "nav.dashboard",   to: "/pharmacy-admin/dashboard" },
    { icon: Package,         key: "nav.stock",        to: "/pharmacy-admin/stock" },
    { icon: ShoppingBag,     key: "nav.orders",       to: "/pharmacy-admin/orders" },
    { icon: Truck,           key: "nav.agents",       to: "/pharmacy-admin/agents" },
    { icon: Clock,           key: "nav.horaires",     to: "/pharmacy-admin/horaires" },
    { icon: MessageSquare,   key: "nav.messaging",    to: "/pharmacy-admin/messaging" },
    { icon: Settings,        key: "nav.settings",     to: "/pharmacy-admin/settings" },
  ],
  cashier: [
    { icon: ClipboardCheck,  key: "nav.confirmation",    to: "/cashier/confirmation" },
    { icon: FileText,        key: "nav.prescriptions",   to: "/cashier/prescriptions" },
    { icon: ShoppingBag,     key: "nav.history",         to: "/cashier/history" },
    { icon: MessageSquare,   key: "nav.messagingAgents", to: "/cashier/messaging" },
  ],
  delivery_agent: [
    { icon: Truck,           key: "nav.deliveries",   to: "/agent/deliveries" },
    { icon: History,         key: "nav.history",      to: "/agent/history" },
  ],
  platform_admin: [
    { icon: LayoutDashboard, key: "nav.dashboard",    to: "/platform-admin/dashboard" },
    { icon: Users,           key: "nav.users",        to: "/platform-admin/users" },
    { icon: Building2,       key: "nav.pharmacies",   to: "/platform-admin/pharmacies" },
    { icon: ShoppingBag,     key: "nav.orders",       to: "/platform-admin/orders" },
    { icon: AlertTriangle,   key: "nav.disputes",     to: "/platform-admin/disputes" },
    { icon: BarChart2,       key: "nav.reports",      to: "/platform-admin/reports" },
    { icon: MessageSquare,   key: "nav.messaging",    to: "/platform-admin/messaging" },
    { icon: Settings,        key: "nav.settings",     to: "/platform-admin/settings" },
  ],
};

const roleRouteMap = {
  pharmacy_admin: "/pharmacy-admin/dashboard",
  cashier:        "/cashier/confirmation",
  delivery_agent: "/agent/deliveries",
  platform_admin: "/platform-admin/dashboard",
};

const ALL_ROLES = ["pharmacy_admin", "cashier", "delivery_agent", "platform_admin"];

export default function DashboardLayout() {
  const { role, setRole } = useRole();
  const t = useT();
  const { lang, setLang } = useLang();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [roleDropdown, setRoleDropdown] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const [notifications, setNotifications] = useState(mockNotifications);
  const navigate = useNavigate();

  const navItems = roleNavKeys[role] || roleNavKeys.pharmacy_admin;
  const color    = roleColorMap[role] || roleColorMap.pharmacy_admin;
  const unreadCount = notifications.filter(n => !n.read).length;

  const handleRoleSwitch = (newRole) => {
    setRole(newRole);
    setRoleDropdown(false);
    navigate(roleRouteMap[newRole]);
  };

  const toggleLang = () => {
    setLang(lang === "fr" ? "en" : "fr");
  };

  const handleLogout = () => {
    localStorage.removeItem("pharmago_token");
    localStorage.removeItem("pharmago_user");
    navigate("/login");
  };

  const user = (() => {
    try {
      return JSON.parse(localStorage.getItem("pharmago_user") || "{}");
    } catch (_) {
      return {};
    }
  })();

  return (
    <div className="flex h-screen overflow-hidden bg-bg">
      {/* Sidebar */}
      <aside
        className={`${sidebarOpen ? "w-64" : "w-18"} transition-all duration-300 flex flex-col shrink-0`}
        style={{ background: "#0D3B36" }}
      >
        {/* Logo */}
        <div className="p-4 border-b border-white/10 flex items-center gap-3">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-lg font-sora shrink-0"
            style={{ background: "#0F9B8E", color: "white" }}
          >
            P
          </div>
          {sidebarOpen && (
            <div>
              <span className="font-bold text-lg tracking-tight font-sora text-white">PharmaGo</span>
              <span className="block text-[10px] text-white/50 -mt-1 font-mono uppercase tracking-wider">
                {t("layout.tagline")}
              </span>
            </div>
          )}
        </div>

        {/* Role badge */}
        <div className="px-3 py-2 mx-3 mt-3 rounded-lg bg-white/5 border border-white/10">
          <div className="flex items-center gap-2">
            <span className={`w-2 h-2 rounded-full ${color}`} />
            {sidebarOpen && (
              <div className="min-w-0">
                <p className="text-xs font-semibold text-white/90 truncate font-sora">
                  {t(`role.${role}`)}
                </p>
                <p className="text-[10px] text-white/50 truncate font-mono">
                  {t(`badge.${role}`)}
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Navigation links */}
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all duration-150 group
                ${isActive
                  ? "bg-primary text-white"
                  : "text-white/60 hover:bg-white/10 hover:text-white"}`
              }
            >
              <item.icon size={18} className="shrink-0" />
              {sidebarOpen && <span className="text-sm font-medium">{t(item.key)}</span>}
            </NavLink>
          ))}
        </nav>

        {/* Logout */}
        <div className="p-3 border-t border-white/10">
          <button
            onClick={handleLogout}
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-white/50 hover:text-white hover:bg-white/10 w-full transition-all cursor-pointer"
          >
            <LogOut size={16} />
            {sidebarOpen && <span className="text-sm">{t("layout.logout")}</span>}
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Topbar */}
        <header className="bg-white border-b px-4 py-3 flex items-center gap-4 shrink-0" style={{ borderColor: "#DCE6E2" }}>
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-500"
          >
            {sidebarOpen ? <X size={18} /> : <Menu size={18} />}
          </button>

          <div className="flex-1" />

          {/* Language Toggle */}
          <button
            onClick={toggleLang}
            title={lang === "fr" ? "Switch to English" : "Passer en français"}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-sm font-semibold transition-all hover:bg-gray-50"
            style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
          >
            <span className="text-base leading-none">{lang === "fr" ? "🇫🇷" : "🇬🇧"}</span>
            <span className="hidden sm:inline text-xs font-bold tracking-wide">{lang === "fr" ? "FR" : "EN"}</span>
          </button>

          {/* Role switcher */}
          <div className="relative">
            <button
              onClick={() => setRoleDropdown(!roleDropdown)}
              className="flex items-center gap-2 px-3 py-2 rounded-lg border text-sm font-medium hover:bg-gray-50 transition-colors"
              style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
            >
              <span className={`w-2 h-2 rounded-full ${color}`} />
              <span className="hidden sm:block">{t("layout.switchRole")}</span>
              <ChevronDown size={14} />
            </button>
            {roleDropdown && (
              <div className="absolute right-0 top-full mt-1 w-52 bg-white rounded-xl shadow-lg border py-1 z-50" style={{ borderColor: "#DCE6E2" }}>
                {ALL_ROLES.map((key) => (
                  <button
                    key={key}
                    onClick={() => handleRoleSwitch(key)}
                    className={`w-full text-left px-4 py-2.5 text-sm hover:bg-gray-50 transition-colors ${role === key ? "text-primary font-semibold" : "text-gray-700"}`}
                  >
                    {t(`role.${key}`)}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Bell Icon / Notification Button */}
          <button
            onClick={() => setNotifOpen(true)}
            className="relative p-2 rounded-lg hover:bg-gray-100 text-gray-500 transition-colors"
          >
            <Bell size={18} />
            {unreadCount > 0 && (
              <span className="absolute top-1.5 right-1.5 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white">
                {unreadCount}
              </span>
            )}
          </button>

          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-semibold font-sora" style={{ background: "#0F9B8E" }}>
              {user.fullName ? user.fullName.charAt(0).toUpperCase() : "A"}
            </div>
            <div className="hidden sm:block">
              <p className="text-sm font-semibold leading-none font-sora" style={{ color: "#0D3B36" }}>{user.fullName || "Admin"}</p>
              <p className="text-xs text-gray-400">{t(`role.${role}`)}</p>
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-auto p-6">
          <Outlet />
        </main>
      </div>

      {/* Notification slide-out */}
      <NotificationPanel
        open={notifOpen}
        onClose={() => setNotifOpen(false)}
        notifications={notifications}
        setNotifications={setNotifications}
      />
    </div>
  );
}
