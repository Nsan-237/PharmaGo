import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Lock, Mail, ShieldCheck, Pill, ShoppingBag, Truck, Eye, EyeOff, Sparkles, ArrowRight, CheckCircle2, AlertCircle } from "lucide-react";
import { useRole } from "../../App";
import { useTranslation, useT } from "../../i18n/TranslationContext";
import { apiLogin } from "../../utils/api";

export default function Login() {
  const navigate = useNavigate();
  const { setRole } = useRole();
  const { lang, toggleLanguage } = useTranslation();
  const isFr = lang === "fr";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  // Preset demo accounts for quick testing
  const presets = [
    {
      roleKey: "platform_admin",
      label: isFr ? "Super Admin" : "Super Admin",
      badge: isFr ? "Plateforme" : "Platform",
      email: "admin@pharmago.cm",
      password: "password123",
      icon: ShieldCheck,
      color: "#6366F1",
      target: "/platform-admin/dashboard",
    },
    {
      roleKey: "pharmacy_admin",
      label: isFr ? "Pharmacien Admin" : "Pharmacy Admin",
      badge: isFr ? "Pharmacie" : "Pharmacy",
      email: "pharma@pharmago.cm",
      password: "password123",
      icon: Pill,
      color: "#0F9B8E",
      target: "/pharmacy-admin/dashboard",
    },
    {
      roleKey: "cashier",
      label: isFr ? "Caissier" : "Cashier",
      badge: isFr ? "Comptoir POS" : "POS Counter",
      email: "cashier@pharmago.cm",
      password: "password123",
      icon: ShoppingBag,
      color: "#3B82F6",
      target: "/cashier/confirmation",
    },
    {
      roleKey: "delivery_agent",
      label: isFr ? "Livreur" : "Delivery Driver",
      badge: isFr ? "Courses" : "Deliveries",
      email: "delivery@pharmago.cm",
      password: "password123",
      icon: Truck,
      color: "#F59E0B",
      target: "/agent/deliveries",
    },
  ];

  const handleSelectPreset = (preset) => {
    setEmail(preset.email);
    setPassword(preset.password);
    setError(null);
  };

  const handleDirectLogin = async (e) => {
    if (e) e.preventDefault();
    if (!email || !password) {
      setError(isFr ? "Veuillez remplir tous les champs" : "Please fill in all fields");
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      // 1. Attempt API login
      const res = await apiLogin(email.trim(), password);
      const user = res.user;
      localStorage.setItem("pharmago_token", res.token);
      localStorage.setItem("pharmago_user", JSON.stringify(user));

      // Map backend role to web role
      let targetPath = "/pharmacy-admin/dashboard";
      let appRole = "pharmacy_admin";

      if (user.role === "PLATFORM_ADMIN") {
        appRole = "platform_admin";
        targetPath = "/platform-admin/dashboard";
      } else if (user.role === "PHARMACY_ADMIN") {
        appRole = "pharmacy_admin";
        targetPath = "/pharmacy-admin/dashboard";
      } else if (user.role === "CASHIER") {
        appRole = "cashier";
        targetPath = "/cashier/confirmation";
      } else if (user.role === "DELIVERY_AGENT") {
        appRole = "delivery_agent";
        targetPath = "/agent/deliveries";
      }

      setRole(appRole);
      navigate(targetPath, { replace: true });
    } catch (err) {
      // If backend fails (e.g. mock mode or unseeded user), allow preset login fallback
      const matchingPreset = presets.find((p) => p.email.toLowerCase() === email.toLowerCase());
      if (matchingPreset) {
        const dummyUser = {
          id: `demo-${matchingPreset.roleKey}`,
          email: matchingPreset.email,
          fullName: matchingPreset.label,
          role: matchingPreset.roleKey.toUpperCase(),
        };
        localStorage.setItem("pharmago_token", "demo_token_2026");
        localStorage.setItem("pharmago_user", JSON.stringify(dummyUser));
        setRole(matchingPreset.roleKey);
        navigate(matchingPreset.target, { replace: true });
        return;
      }

      setError(
        err.message ||
          (isFr
            ? "Identifiants invalides ou serveur indisponible"
            : "Invalid credentials or server unavailable")
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div
      className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden"
      style={{ backgroundColor: "#F6F5EF" }}
    >
      {/* Background Decorative Rings */}
      <div
        className="absolute -top-32 -left-32 w-96 h-96 rounded-full blur-3xl opacity-30 pointer-events-none"
        style={{ background: "#0F9B8E" }}
      />
      <div
        className="absolute -bottom-32 -right-32 w-96 h-96 rounded-full blur-3xl opacity-20 pointer-events-none"
        style={{ background: "#0D3B36" }}
      />

      <div className="w-full max-w-xl z-10">
        {/* Top Header & Language */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div
              className="w-12 h-12 rounded-2xl flex items-center justify-center shadow-md"
              style={{ background: "#0D3B36" }}
            >
              <Pill size={24} className="text-[#0F9B8E]" />
            </div>
            <div>
              <h1 className="text-xl font-bold font-sora" style={{ color: "#0D3B36" }}>
                PharmaGo
              </h1>
              <p className="text-xs text-gray-500 font-medium">
                {isFr ? "Portail Professionnel • Cameroun" : "Professional Portal • Cameroon"}
              </p>
            </div>
          </div>

          <button
            onClick={toggleLanguage}
            type="button"
            className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white border border-gray-200 text-xs font-semibold shadow-xs hover:bg-gray-50 transition-colors"
            style={{ color: "#0D3B36" }}
          >
            <span>{isFr ? "🇫🇷 FR" : "🇬🇧 EN"}</span>
          </button>
        </div>

        {/* Main Card */}
        <div className="bg-white rounded-3xl shadow-xl border border-gray-100 p-8">
          <div className="mb-6">
            <h2 className="text-2xl font-bold font-sora mb-2" style={{ color: "#0D3B36" }}>
              {isFr ? "Connexion au portail" : "Sign in to portal"}
            </h2>
            <p className="text-sm text-gray-500">
              {isFr
                ? "Accédez aux outils de gestion pour votre pharmacie, caisse ou administration."
                : "Access management tools for your pharmacy, POS cashier, or administration."}
            </p>
          </div>

          {error && (
            <div className="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 flex items-start gap-3">
              <AlertCircle size={18} className="text-red-500 shrink-0 mt-0.5" />
              <p className="text-xs text-red-700 font-medium">{error}</p>
            </div>
          )}

          <form onSubmit={handleDirectLogin} className="space-y-4">
            {/* Email Field */}
            <div>
              <label className="block text-xs font-semibold text-gray-700 mb-1.5">
                {isFr ? "Adresse e-mail ou téléphone" : "Email address or phone"}
              </label>
              <div className="relative">
                <Mail size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder={isFr ? "ex: admin@pharmago.cm" : "e.g. admin@pharmago.cm"}
                  className="w-full pl-10 pr-4 py-3 rounded-xl border text-sm outline-none transition-all focus:border-[#0F9B8E] focus:ring-2 focus:ring-[#0F9B8E]/20"
                  style={{ borderColor: "#DCE6E2", background: "#FBFBFA" }}
                  required
                />
              </div>
            </div>

            {/* Password Field */}
            <div>
              <label className="block text-xs font-semibold text-gray-700 mb-1.5">
                {isFr ? "Mot de passe" : "Password"}
              </label>
              <div className="relative">
                <Lock size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-10 py-3 rounded-xl border text-sm outline-none transition-all focus:border-[#0F9B8E] focus:ring-2 focus:ring-[#0F9B8E]/20"
                  style={{ borderColor: "#DCE6E2", background: "#FBFBFA" }}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3.5 rounded-xl font-bold text-white text-sm flex items-center justify-center gap-2 shadow-md transition-all hover:opacity-95 active:scale-[0.99] cursor-pointer"
              style={{ background: "#0F9B8E" }}
            >
              {isLoading ? (
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <span>{isFr ? "Se connecter" : "Sign In"}</span>
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </form>

          {/* Quick Demo Presets */}
          <div className="mt-8 pt-6 border-t border-gray-100">
            <div className="flex items-center gap-2 mb-3">
              <Sparkles size={16} className="text-[#0F9B8E]" />
              <span className="text-xs font-bold uppercase tracking-wider text-gray-500">
                {isFr ? "Accès Rapide Démo (1 Clic)" : "Quick Demo Access (1 Click)"}
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2.5">
              {presets.map((preset) => {
                const IconComponent = preset.icon;
                const isSelected = email.toLowerCase() === preset.email.toLowerCase();

                return (
                  <button
                    key={preset.roleKey}
                    type="button"
                    onClick={() => handleSelectPreset(preset)}
                    className={`p-3 rounded-xl border text-left flex items-start gap-2.5 transition-all cursor-pointer ${
                      isSelected
                        ? "border-[#0F9B8E] bg-[#E8F6F4] shadow-xs"
                        : "border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50"
                    }`}
                  >
                    <div
                      className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 text-white"
                      style={{ backgroundColor: preset.color }}
                    >
                      <IconComponent size={16} />
                    </div>
                    <div className="overflow-hidden">
                      <p className="text-xs font-bold truncate" style={{ color: "#0D3B36" }}>
                        {preset.label}
                      </p>
                      <p className="text-[11px] text-gray-400 truncate">{preset.badge}</p>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Footer info */}
        <p className="text-center text-xs text-gray-400 mt-6">
          © 2026 PharmaGo Cameroon Ltd. • Douala • Yaoundé • Bafoussam
        </p>
      </div>
    </div>
  );
}
