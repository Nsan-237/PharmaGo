import React, { useState } from "react";
import { Save, CheckCircle, Building2, Truck, AlertTriangle, Globe, CreditCard, MapPin } from "lucide-react";
import { useRole } from "../../App";
import { useT } from "../../i18n/TranslationContext";
import { PageHeader, Card, PrimaryButton, InputField } from "../../components/shared/UI";

/* ─── Reusable sub-components ─────────────────────────────────── */

function SectionHeader({ icon: Icon, title, description }) {
  return (
    <div className="p-4 border-b flex items-start gap-3" style={{ borderColor: "#DCE6E2" }}>
      <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 mt-0.5" style={{ background: "#e6f7f6" }}>
        <Icon size={16} style={{ color: "#0F9B8E" }} />
      </div>
      <div>
        <p className="font-semibold font-sora text-sm" style={{ color: "#0D3B36" }}>{title}</p>
        {description && <p className="text-xs text-gray-400 mt-0.5">{description}</p>}
      </div>
    </div>
  );
}

function Toggle({ checked, onChange, label, description }) {
  return (
    <div className="flex items-center justify-between py-3">
      <div>
        <p className="text-sm font-medium" style={{ color: "#0D3B36" }}>{label}</p>
        {description && <p className="text-xs text-gray-400 mt-0.5">{description}</p>}
      </div>
      <div
        className={`relative w-11 h-6 rounded-full cursor-pointer transition-colors duration-200 shrink-0 ml-4`}
        style={{ background: checked ? "#0F9B8E" : "#e5e7eb" }}
        onClick={() => onChange(!checked)}
      >
        <div className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow transition-transform duration-200 ${checked ? "translate-x-5" : "translate-x-1"}`} />
      </div>
    </div>
  );
}

function SaveToast({ visible, t }) {
  if (!visible) return null;
  return (
    <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 px-5 py-3.5 rounded-xl shadow-2xl text-white animate-fade-in"
      style={{ background: "#0F9B8E" }}>
      <CheckCircle size={18} />
      <span className="font-semibold text-sm">{t("settings.saved")}</span>
    </div>
  );
}

/* ─── Pharmacy Admin Settings ──────────────────────────────────── */

function PharmacySettings({ onSave, t }) {
  const [general, setGeneral] = useState({
    name:    "Pharmacie du Centre",
    address: "Rue de la Réunification, Douala",
    phone:   "+237 233 42 15 80",
    city:    "Douala",
  });
  const [delivery, setDelivery] = useState({ enabled: true, fee: 500, minOrder: 1000 });
  const [stockThreshold, setStockThreshold] = useState(30);

  return (
    <div className="space-y-6">
      {/* General Info */}
      <Card>
        <SectionHeader icon={Building2} title={t("settings.pharma.generalTitle")} description={t("settings.pharma.generalDesc")} />
        <div className="p-5 space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <InputField label={t("settings.pharma.fieldName")} value={general.name}
              onChange={e => setGeneral(g => ({ ...g, name: e.target.value }))} required />
            <InputField label={t("settings.pharma.fieldCity")} value={general.city}
              onChange={e => setGeneral(g => ({ ...g, city: e.target.value }))} />
          </div>
          <InputField label={t("settings.pharma.fieldAddress")} value={general.address}
            onChange={e => setGeneral(g => ({ ...g, address: e.target.value }))} />
          <InputField label={t("settings.pharma.fieldPhone")} value={general.phone}
            onChange={e => setGeneral(g => ({ ...g, phone: e.target.value }))} />
        </div>
      </Card>

      {/* Delivery Options */}
      <Card>
        <SectionHeader icon={Truck} title={t("settings.pharma.deliveryTitle")} description={t("settings.pharma.deliveryDesc")} />
        <div className="p-5 space-y-1 divide-y" style={{ borderColor: "#DCE6E2" }}>
          <Toggle
            checked={delivery.enabled}
            onChange={v => setDelivery(d => ({ ...d, enabled: v }))}
            label={t("settings.pharma.deliveryToggle")}
            description={t("settings.pharma.deliveryToggleDesc")}
          />
          <div className={`pt-3 space-y-4 transition-opacity ${delivery.enabled ? "opacity-100" : "opacity-40 pointer-events-none"}`}>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>{t("settings.pharma.deliveryFee")}</label>
                <input type="number" value={delivery.fee}
                  onChange={e => setDelivery(d => ({ ...d, fee: parseInt(e.target.value) || 0 }))}
                  className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }} />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>{t("settings.pharma.minOrder")}</label>
                <input type="number" value={delivery.minOrder}
                  onChange={e => setDelivery(d => ({ ...d, minOrder: parseInt(e.target.value) || 0 }))}
                  className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }} />
              </div>
            </div>
            <div className="p-3 rounded-lg text-sm" style={{ background: "#e6f7f6" }}>
              <span style={{ color: "#0D3B36" }}>
                {t("settings.pharma.deliverySummaryPre")} <strong>{delivery.minOrder.toLocaleString()} FCFA</strong> {t("settings.pharma.deliverySummaryMid")} <strong>{delivery.fee.toLocaleString()} FCFA</strong>.
              </span>
            </div>
          </div>
        </div>
      </Card>

      {/* Stock Alert Threshold */}
      <Card>
        <SectionHeader icon={AlertTriangle} title={t("settings.pharma.stockTitle")} description={t("settings.pharma.stockDesc")} />
        <div className="p-5">
          <div className="flex items-center gap-5">
            <div className="flex-1">
              <input type="range" min="5" max="100" value={stockThreshold}
                onChange={e => setStockThreshold(parseInt(e.target.value))}
                className="w-full accent-primary" />
              <div className="flex justify-between text-xs text-gray-400 mt-1">
                <span>5</span><span>100</span>
              </div>
            </div>
            <div className="w-24 text-center py-2 rounded-xl font-bold font-sora text-xl shrink-0" style={{ background: "#FEF3DC", color: "#E8A33D" }}>
              {stockThreshold}
            </div>
          </div>
          <p className="text-xs text-gray-500 mt-3">
            {t("settings.pharma.stockSummaryPre")} <strong>{stockThreshold} {t("settings.pharma.units")}</strong> {t("settings.pharma.stockSummaryPost")}
          </p>
        </div>
      </Card>

      <div className="flex justify-end">
        <PrimaryButton onClick={onSave}><Save size={15} /> {t("settings.saveBtn")}</PrimaryButton>
      </div>
    </div>
  );
}

/* ─── Platform Admin Settings ─────────────────────────────────── */

const CITIES = ["Douala","Yaoundé","Bafoussam","Garoua","Limbe","Bamenda","Buea"];

function PlatformSettings({ onSave, t }) {
  const [rules, setRules] = useState({ commission: 8, deliveryRadius: 15, autoApprove: false });
  const [activeCities,    setActiveCities]    = useState(["Douala","Yaoundé","Limbe"]);
  const [momoKey,         setMomoKey]         = useState("MTN-XCA-PRD-xxxxxx");
  const [orangeKey,       setOrangeKey]       = useState("OM-CM-LIVE-xxxxxx");
  const [momoMerchant,    setMomoMerchant]    = useState("PHARMAGO_CM");
  const [orangeMerchant,  setOrangeMerchant]  = useState("PHARMAGO_OM");

  const toggleCity = (city) => setActiveCities(prev => prev.includes(city) ? prev.filter(c => c !== city) : [...prev, city]);

  return (
    <div className="space-y-6">
      {/* Global Rules */}
      <Card>
        <SectionHeader icon={Globe} title={t("settings.plat.rulesTitle")} description={t("settings.plat.rulesDesc")} />
        <div className="p-5 space-y-5">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>{t("settings.plat.commission")}</label>
              <div className="flex items-center gap-3">
                <input type="range" min="1" max="25" value={rules.commission}
                  onChange={e => setRules(r => ({ ...r, commission: parseInt(e.target.value) }))}
                  className="flex-1 accent-primary" />
                <span className="w-12 text-center py-1 rounded-lg font-bold font-sora" style={{ background: "#e6f7f6", color: "#0F9B8E" }}>
                  {rules.commission}%
                </span>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>{t("settings.plat.radius")}</label>
              <div className="flex items-center gap-3">
                <input type="range" min="1" max="50" value={rules.deliveryRadius}
                  onChange={e => setRules(r => ({ ...r, deliveryRadius: parseInt(e.target.value) }))}
                  className="flex-1 accent-primary" />
                <span className="w-14 text-center py-1 rounded-lg font-bold font-sora" style={{ background: "#e6f7f6", color: "#0F9B8E" }}>
                  {rules.deliveryRadius} km
                </span>
              </div>
            </div>
          </div>
          <div className="divide-y" style={{ borderColor: "#DCE6E2" }}>
            <Toggle
              checked={rules.autoApprove}
              onChange={v => setRules(r => ({ ...r, autoApprove: v }))}
              label={t("settings.plat.autoApprove")}
              description={t("settings.plat.autoApproveDesc")}
            />
          </div>
          {rules.autoApprove && (
            <div className="flex items-start gap-2 p-3 rounded-lg text-sm" style={{ background: "#FEF3DC" }}>
              <AlertTriangle size={15} className="shrink-0 mt-0.5" style={{ color: "#E8A33D" }} />
              <p style={{ color: "#0D3B36" }}>{t("settings.plat.autoApproveWarn")}</p>
            </div>
          )}
        </div>
      </Card>

      {/* Coverage Zones */}
      <Card>
        <SectionHeader icon={MapPin} title={t("settings.plat.zonesTitle")} description={t("settings.plat.zonesDesc")} />
        <div className="p-5">
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
            {CITIES.map(city => {
              const active = activeCities.includes(city);
              return (
                <button key={city} onClick={() => toggleCity(city)}
                  className="flex items-center gap-2 p-3 rounded-xl border-2 text-sm font-medium transition-all"
                  style={{ borderColor: active ? "#0F9B8E" : "#DCE6E2", background: active ? "#e6f7f6" : "white", color: active ? "#0D3B36" : "#6b7280" }}>
                  <span className="w-2 h-2 rounded-full shrink-0" style={{ background: active ? "#0F9B8E" : "#d1d5db" }} />
                  {city}
                </button>
              );
            })}
          </div>
          <p className="text-xs text-gray-400 mt-3">
            {activeCities.length} {t("settings.plat.activeCities")}: {activeCities.join(", ")}
          </p>
        </div>
      </Card>

      {/* Payment Gateways */}
      <Card>
        <SectionHeader icon={CreditCard} title={t("settings.plat.payTitle")} description={t("settings.plat.payDesc")} />
        <div className="p-5 space-y-5">
          {/* MTN MoMo */}
          <div className="p-4 rounded-xl border" style={{ borderColor: "#DCE6E2" }}>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs" style={{ background: "#FFCC00", color: "#0D3B36" }}>M</div>
              <span className="font-semibold text-sm" style={{ color: "#0D3B36" }}>MTN Mobile Money</span>
              <span className="ml-auto text-xs px-2 py-0.5 rounded-full bg-green-50 text-green-600 font-medium">{t("settings.plat.active")}</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium mb-1" style={{ color: "#0D3B36" }}>{t("settings.plat.apiKey")}</label>
                <input type="password" value={momoKey} onChange={e => setMomoKey(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border text-sm font-mono outline-none" style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }} />
              </div>
              <div>
                <label className="block text-xs font-medium mb-1" style={{ color: "#0D3B36" }}>{t("settings.plat.merchantCode")}</label>
                <input type="text" value={momoMerchant} onChange={e => setMomoMerchant(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border text-sm font-mono outline-none" style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }} />
              </div>
            </div>
          </div>

          {/* Orange Money */}
          <div className="p-4 rounded-xl border" style={{ borderColor: "#DCE6E2" }}>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs text-white" style={{ background: "#FF6600" }}>O</div>
              <span className="font-semibold text-sm" style={{ color: "#0D3B36" }}>Orange Money</span>
              <span className="ml-auto text-xs px-2 py-0.5 rounded-full bg-green-50 text-green-600 font-medium">{t("settings.plat.active")}</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium mb-1" style={{ color: "#0D3B36" }}>{t("settings.plat.apiKey")}</label>
                <input type="password" value={orangeKey} onChange={e => setOrangeKey(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border text-sm font-mono outline-none" style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }} />
              </div>
              <div>
                <label className="block text-xs font-medium mb-1" style={{ color: "#0D3B36" }}>{t("settings.plat.merchantCode")}</label>
                <input type="text" value={orangeMerchant} onChange={e => setOrangeMerchant(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border text-sm font-mono outline-none" style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }} />
              </div>
            </div>
          </div>
        </div>
      </Card>

      <div className="flex justify-end">
        <PrimaryButton onClick={onSave}><Save size={15} /> {t("settings.saveBtn")}</PrimaryButton>
      </div>
    </div>
  );
}

/* ─── Main export ──────────────────────────────────────────────── */

export default function SettingsPage() {
  const { role } = useRole();
  const t = useT();
  const [saved, setSaved] = useState(false);

  const handleSave = () => { setSaved(true); setTimeout(() => setSaved(false), 2500); };

  return (
    <div>
      <PageHeader
        title={t("settings.title")}
        subtitle={role === "platform_admin" ? t("settings.platSubtitle") : t("settings.pharmaSubtitle")}
      />

      {(role === "pharmacy_admin" || role === "cashier") && (
        <PharmacySettings onSave={handleSave} t={t} />
      )}
      {role === "platform_admin" && (
        <PlatformSettings onSave={handleSave} t={t} />
      )}
      {role === "delivery_agent" && (
        <Card className="p-12 text-center">
          <p className="font-semibold font-sora text-gray-500">{t("settings.agent.title")}</p>
          <p className="text-sm text-gray-400 mt-1">{t("settings.agent.desc")}</p>
        </Card>
      )}

      <SaveToast visible={saved} t={t} />
    </div>
  );
}
