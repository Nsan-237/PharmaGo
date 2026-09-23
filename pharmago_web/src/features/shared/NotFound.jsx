import React from "react";
import { useNavigate } from "react-router-dom";
import { Home, ArrowLeft, Pill, Search } from "lucide-react";
import { useRole } from "../../App";

/**
 * PharmaGo — 404 Not Found Page
 * Shown when a user navigates to an unknown route.
 */
export default function NotFound() {
  const navigate = useNavigate();
  const { role } = useRole();

  const homeRoute = {
    platform_admin:  "/platform-admin/dashboard",
    pharmacy_admin:  "/pharmacy-admin/dashboard",
    cashier:         "/cashier/confirmation",
    delivery_agent:  "/agent/deliveries",
  }[role] || "/";

  return (
    <div
      className="min-h-screen flex items-center justify-center p-6 relative overflow-hidden"
      style={{ background: "#F6F5EF" }}
    >
      {/* Decorative background blobs */}
      <div
        className="absolute -top-40 -left-40 w-96 h-96 rounded-full blur-3xl opacity-20 pointer-events-none"
        style={{ background: "#0F9B8E" }}
      />
      <div
        className="absolute -bottom-40 -right-40 w-96 h-96 rounded-full blur-3xl opacity-15 pointer-events-none"
        style={{ background: "#0D3B36" }}
      />

      <div className="relative z-10 text-center max-w-md w-full animate-fade-in-up">
        {/* Logo */}
        <div className="flex items-center justify-center gap-3 mb-10">
          <div
            className="w-12 h-12 rounded-2xl flex items-center justify-center shadow-lg"
            style={{ background: "#0D3B36" }}
          >
            <Pill size={22} style={{ color: "#0F9B8E" }} />
          </div>
          <span className="text-xl font-bold font-sora" style={{ color: "#0D3B36" }}>
            PharmaGo
          </span>
        </div>

        {/* 404 number */}
        <div
          className="text-9xl font-black font-sora mb-2 leading-none select-none"
          style={{
            background: "linear-gradient(135deg, #0F9B8E 0%, #0D3B36 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          404
        </div>

        <div className="mb-8">
          <h1 className="text-2xl font-bold font-sora mb-3" style={{ color: "#0D3B36" }}>
            Page introuvable
          </h1>
          <p className="text-gray-500 leading-relaxed">
            La page que vous recherchez n'existe pas ou a été déplacée.
            <br />
            <span className="text-sm">
              The page you're looking for doesn't exist or has been moved.
            </span>
          </p>
        </div>

        {/* Action buttons */}
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <button
            onClick={() => navigate(-1)}
            className="flex items-center justify-center gap-2 px-5 py-3 rounded-xl border font-semibold text-sm transition-all hover:bg-gray-100 active:scale-95"
            style={{ borderColor: "#DCE6E2", color: "#0D3B36", background: "white" }}
          >
            <ArrowLeft size={16} />
            Retour / Go back
          </button>
          <button
            onClick={() => navigate(homeRoute)}
            className="flex items-center justify-center gap-2 px-5 py-3 rounded-xl text-white font-semibold text-sm shadow-md transition-all hover:opacity-90 active:scale-95"
            style={{ background: "#0F9B8E" }}
          >
            <Home size={16} />
            Tableau de bord / Dashboard
          </button>
        </div>

        {/* Decorative pharmacy pills */}
        <div className="mt-14 flex items-center justify-center gap-2 opacity-20 select-none">
          {["💊", "🏥", "💉", "🩺", "🔬"].map((emoji, i) => (
            <span key={i} className="text-2xl animate-fade-in-up" style={{ animationDelay: `${i * 80}ms` }}>
              {emoji}
            </span>
          ))}
        </div>

        <p className="text-xs text-gray-400 mt-6">© 2026 PharmaGo Cameroon Ltd.</p>
      </div>
    </div>
  );
}
