import React from "react";

export function StatCard({ title, value, icon: Icon, color = "#0F9B8E", bg = "#e6f7f6", trend, subtitle }) {
  return (
    <div className="bg-white rounded-xl p-5 border flex items-start gap-4" style={{ borderColor: "#DCE6E2" }}>
      <div className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0" style={{ background: bg }}>
        <Icon size={20} style={{ color }} />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm text-gray-500 mb-0.5">{title}</p>
        <p className="text-2xl font-bold font-sora" style={{ color: "#0D3B36" }}>{value}</p>
        {subtitle && <p className="text-xs text-gray-400 mt-0.5">{subtitle}</p>}
        {trend && (
          <p className={`text-xs mt-1 font-medium ${trend.positive ? "text-green-600" : "text-red-500"}`}>
            {trend.positive ? "↑" : "↓"} {trend.value}
          </p>
        )}
      </div>
    </div>
  );
}

export function PageHeader({ title, subtitle, action }) {
  return (
    <div className="flex items-start justify-between mb-6">
      <div>
        <h1 className="text-2xl font-bold font-sora" style={{ color: "#0D3B36" }}>{title}</h1>
        {subtitle && <p className="text-gray-500 text-sm mt-1">{subtitle}</p>}
      </div>
      {action && <div>{action}</div>}
    </div>
  );
}

export function Card({ children, className = "" }) {
  return (
    <div className={`bg-white rounded-xl border ${className}`} style={{ borderColor: "#DCE6E2" }}>
      {children}
    </div>
  );
}

export function PrimaryButton({ children, onClick, className = "", type = "button", disabled = false }) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-lg text-white text-sm font-semibold transition-all
        ${disabled ? "opacity-50 cursor-not-allowed" : "hover:opacity-90 active:scale-95"}
        ${className}`}
      style={{ background: disabled ? "#94a3b8" : "#0F9B8E" }}
    >
      {children}
    </button>
  );
}

export function DangerButton({ children, onClick, className = "" }) {
  return (
    <button
      onClick={onClick}
      className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-lg text-white text-sm font-semibold bg-red-500 hover:bg-red-600 transition-all active:scale-95 ${className}`}
    >
      {children}
    </button>
  );
}

export function SecondaryButton({ children, onClick, className = "" }) {
  return (
    <button
      onClick={onClick}
      className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold border transition-all hover:bg-gray-50 active:scale-95 ${className}`}
      style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
    >
      {children}
    </button>
  );
}

export function Modal({ open, onClose, title, children, width = "max-w-lg" }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative bg-white rounded-2xl shadow-2xl w-full ${width} max-h-[90vh] overflow-y-auto`} style={{ boxShadow: "0 20px 60px rgba(0,0,0,0.12)" }}>
        <div className="flex items-center justify-between p-5 border-b" style={{ borderColor: "#DCE6E2" }}>
          <h2 className="text-lg font-bold font-sora" style={{ color: "#0D3B36" }}>{title}</h2>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 transition-colors">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>
        <div className="p-5">{children}</div>
      </div>
    </div>
  );
}

export function TableWrapper({ children }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">{children}</table>
    </div>
  );
}

export function Th({ children, className = "" }) {
  return (
    <th className={`text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide bg-gray-50 border-b ${className}`} style={{ borderColor: "#DCE6E2" }}>
      {children}
    </th>
  );
}

export function Td({ children, className = "" }) {
  return (
    <td className={`px-4 py-3 border-b ${className}`} style={{ borderColor: "#DCE6E2", color: "#374151" }}>
      {children}
    </td>
  );
}

export function InputField({ label, type = "text", value, onChange, placeholder, required }) {
  return (
    <div>
      <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>{label}{required && <span className="text-red-500 ml-0.5">*</span>}</label>
      <input
        type={type}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        required={required}
        className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none transition-all focus:ring-2"
        style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }}
        onFocus={e => e.target.style.borderColor = "#0F9B8E"}
        onBlur={e => e.target.style.borderColor = "#DCE6E2"}
      />
    </div>
  );
}

export function SelectField({ label, value, onChange, options, required }) {
  return (
    <div>
      <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>{label}{required && <span className="text-red-500 ml-0.5">*</span>}</label>
      <select
        value={value}
        onChange={onChange}
        required={required}
        className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none bg-white transition-all"
        style={{ borderColor: "#DCE6E2" }}
      >
        {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </div>
  );
}
