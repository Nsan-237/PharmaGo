import React, { createContext, useContext, useState, useCallback } from "react";
import { CheckCircle, XCircle, AlertTriangle, Info, X } from "lucide-react";

/**
 * PharmaGo — Global Toast Notification System
 * Usage:
 *   const toast = useToast();
 *   toast.success("Pharmacy approved!");
 *   toast.error("Something went wrong");
 *   toast.warning("Low stock detected");
 *   toast.info("New order received");
 */

const ToastContext = createContext(null);

const ICONS = {
  success: { icon: CheckCircle, color: "#16A34A", bg: "#DCFCE7", border: "#86EFAC" },
  error:   { icon: XCircle,     color: "#DC2626", bg: "#FEE2E2", border: "#FCA5A5" },
  warning: { icon: AlertTriangle,color: "#D97706", bg: "#FEF3C7", border: "#FCD34D" },
  info:    { icon: Info,         color: "#2563EB", bg: "#DBEAFE", border: "#93C5FD" },
};

function ToastItem({ toast, onDismiss }) {
  const meta = ICONS[toast.type] || ICONS.info;
  const Icon = meta.icon;

  return (
    <div
      className="toast-enter flex items-start gap-3 p-4 rounded-xl shadow-lg w-full max-w-sm border"
      style={{ background: meta.bg, borderColor: meta.border }}
      role="alert"
    >
      <Icon size={18} style={{ color: meta.color }} className="shrink-0 mt-0.5" />
      <div className="flex-1 min-w-0">
        {toast.title && (
          <p className="text-sm font-semibold mb-0.5 font-sora" style={{ color: "#0D3B36" }}>
            {toast.title}
          </p>
        )}
        <p className="text-sm" style={{ color: "#374151" }}>{toast.message}</p>
      </div>
      <button
        onClick={() => onDismiss(toast.id)}
        className="p-0.5 rounded-md hover:bg-black/10 transition-colors shrink-0"
        style={{ color: meta.color }}
      >
        <X size={14} />
      </button>
    </div>
  );
}

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const dismiss = useCallback((id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  const show = useCallback((message, type = "info", title = null, duration = 4000) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, message, type, title }]);
    if (duration > 0) {
      setTimeout(() => dismiss(id), duration);
    }
    return id;
  }, [dismiss]);

  const toast = {
    success: (message, title) => show(message, "success", title),
    error:   (message, title) => show(message, "error",   title),
    warning: (message, title) => show(message, "warning", title),
    info:    (message, title) => show(message, "info",    title),
    dismiss,
  };

  return (
    <ToastContext.Provider value={toast}>
      {children}
      {/* Toast container — fixed top-right */}
      <div
        className="fixed top-4 right-4 z-[9999] flex flex-col gap-2 pointer-events-none"
        aria-live="polite"
      >
        {toasts.map(t => (
          <div key={t.id} className="pointer-events-auto">
            <ToastItem toast={t} onDismiss={dismiss} />
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToast must be used within <ToastProvider>");
  return ctx;
}
