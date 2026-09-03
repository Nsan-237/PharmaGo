import React from "react";
import { X, Check, Bell, Package, AlertTriangle, MessageSquare, ShoppingBag } from "lucide-react";
import { useT } from "../../i18n/TranslationContext";

const mockNotifications = [
  {
    id: "notif-1",
    type: "order",
    icon: ShoppingBag,
    iconColor: "#0F9B8E",
    iconBg: "#e6f7f6",
    titleKey: "notif.newOrderTitle",
    descKey: "notif.newOrderDesc",
    time: "5 min",
    read: false,
  },
  {
    id: "notif-2",
    type: "stock",
    icon: Package,
    iconColor: "#E8A33D",
    iconBg: "#FEF3DC",
    titleKey: "notif.stockAlertTitle",
    descKey: "notif.stockAlertDesc",
    time: "25 min",
    read: false,
  },
  {
    id: "notif-3",
    type: "dispute",
    icon: AlertTriangle,
    iconColor: "#dc2626",
    iconBg: "#fee2e2",
    titleKey: "notif.disputeTitle",
    descKey: "notif.disputeDesc",
    time: "2 h",
    read: false,
  },
  {
    id: "notif-4",
    type: "message",
    icon: MessageSquare,
    iconColor: "#2563eb",
    iconBg: "#dbeafe",
    titleKey: "notif.msgTitle",
    descKey: "notif.msgDesc",
    time: "4 h",
    read: true,
  },
];

export default function NotificationPanel({ open, onClose, notifications, setNotifications }) {
  const t = useT();

  if (!open) return null;

  const markAllAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  };

  const markOneAsRead = (id) => {
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n));
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <div className="fixed inset-0 z-50 overflow-hidden flex justify-end">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/30 backdrop-blur-xs transition-opacity"
        onClick={onClose}
      />

      {/* Slide-out panel */}
      <div className="relative w-full max-w-sm bg-white h-full shadow-2xl flex flex-col z-10 animate-slide-in-right">
        {/* Header */}
        <div className="p-4 border-b flex items-center justify-between" style={{ borderColor: "#DCE6E2" }}>
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: "#e6f7f6" }}>
              <Bell size={16} style={{ color: "#0F9B8E" }} />
            </div>
            <div>
              <h3 className="font-semibold text-sm font-sora" style={{ color: "#0D3B36" }}>
                {t("notif.title")}
              </h3>
              <p className="text-xs text-gray-400">
                {unreadCount} {t("notif.unread")}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {unreadCount > 0 && (
              <button
                onClick={markAllAsRead}
                title={t("notif.markAllRead")}
                className="text-xs font-medium px-2 py-1 rounded hover:bg-gray-100 transition-colors"
                style={{ color: "#0F9B8E" }}
              >
                {t("notif.markAllReadShort")}
              </button>
            )}
            <button
              onClick={onClose}
              className="p-1 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Notifications List */}
        <div className="flex-1 overflow-y-auto divide-y" style={{ borderColor: "#F6F5EF" }}>
          {notifications.map((n) => {
            const Icon = n.icon;
            return (
              <div
                key={n.id}
                onClick={() => markOneAsRead(n.id)}
                className={`p-4 flex items-start gap-3 transition-colors cursor-pointer ${
                  n.read ? "bg-white hover:bg-gray-50" : "bg-teal-50/40 hover:bg-teal-50/70"
                }`}
              >
                <div
                  className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 mt-0.5"
                  style={{ background: n.iconBg }}
                >
                  <Icon size={16} style={{ color: n.iconColor }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-0.5">
                    <p
                      className={`text-xs font-semibold truncate ${
                        n.read ? "text-gray-700" : "text-teal-950 font-bold"
                      }`}
                    >
                      {t(n.titleKey)}
                    </p>
                    <span className="text-[10px] text-gray-400 shrink-0 ml-1">{n.time}</span>
                  </div>
                  <p className="text-xs text-gray-500 leading-relaxed">{t(n.descKey)}</p>
                </div>
                {!n.read && (
                  <span
                    className="w-2 h-2 rounded-full mt-2 shrink-0"
                    style={{ background: "#0F9B8E" }}
                  />
                )}
              </div>
            );
          })}
        </div>

        {/* Footer */}
        <div className="p-3 border-t bg-gray-50 text-center" style={{ borderColor: "#DCE6E2" }}>
          <p className="text-xs text-gray-400">PharmaGo Realtime Feed</p>
        </div>
      </div>
    </div>
  );
}

export { mockNotifications };
