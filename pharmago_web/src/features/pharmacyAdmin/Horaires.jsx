import React, { useState } from "react";
import { Clock, Info } from "lucide-react";
import { useT } from "../../i18n/TranslationContext";
import { PageHeader, Card, PrimaryButton, SecondaryButton } from "../../components/shared/UI";

const DAY_KEYS = ["Lundi","Mardi","Mercredi","Jeudi","Vendredi","Samedi","Dimanche"];

const defaultHours = {
  Lundi:    { open: "08:00", close: "20:00", closed: false },
  Mardi:    { open: "08:00", close: "20:00", closed: false },
  Mercredi: { open: "08:00", close: "20:00", closed: false },
  Jeudi:    { open: "08:00", close: "20:00", closed: false },
  Vendredi: { open: "08:00", close: "20:00", closed: false },
  Samedi:   { open: "09:00", close: "18:00", closed: false },
  Dimanche: { open: "10:00", close: "14:00", closed: true },
};

export default function PharmaHoraires() {
  const t = useT();
  const [override, setOverride] = useState(false);
  const [hours, setHours] = useState(defaultHours);
  const [deliveryStart, setDeliveryStart] = useState("09:30");
  const [deliveryEnd,   setDeliveryEnd]   = useState("16:30");
  const [saved, setSaved] = useState(false);

  const handleSave = () => { setSaved(true); setTimeout(() => setSaved(false), 2000); };
  const updateDay  = (day, field, val) => setHours(prev => ({ ...prev, [day]: { ...prev[day], [field]: val } }));

  return (
    <div>
      <PageHeader title={t("horaires.title")} subtitle={t("horaires.subtitle")} />

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <Card className="xl:col-span-2">
          <div className="p-4 border-b flex items-center justify-between" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("horaires.weekly")}</h2>
            <div className="flex items-center gap-3">
              <span className="text-sm text-gray-500">{t("horaires.override")}</span>
              <div
                className={`relative w-10 h-5 rounded-full cursor-pointer transition-colors ${override ? "bg-primary" : "bg-gray-200"}`}
                style={{ background: override ? "#0F9B8E" : undefined }}
                onClick={() => setOverride(!override)}
              >
                <div className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform ${override ? "translate-x-5" : "translate-x-0.5"}`} />
              </div>
            </div>
          </div>

          {!override && (
            <div className="mx-4 my-3 flex items-start gap-2 p-3 rounded-lg text-sm" style={{ background: "#e6f7f6", color: "#0D3B36" }}>
              <Info size={15} className="mt-0.5 shrink-0" style={{ color: "#0F9B8E" }} />
              <p>{t("horaires.readOnly")}</p>
            </div>
          )}

          <div className="p-4 space-y-3">
            {DAY_KEYS.map(day => (
              <div key={day} className="flex items-center gap-4">
                <span className="w-24 text-sm font-medium shrink-0" style={{ color: "#0D3B36" }}>{day}</span>
                <label className="flex items-center gap-1.5 cursor-pointer shrink-0">
                  <input type="checkbox" checked={hours[day].closed} onChange={e => updateDay(day,"closed",e.target.checked)} disabled={!override} className="accent-primary" />
                  <span className="text-xs text-gray-500">{t("horaires.closed")}</span>
                </label>
                {!hours[day].closed ? (
                  <div className="flex items-center gap-2">
                    <input type="time" value={hours[day].open}  onChange={e => updateDay(day,"open",e.target.value)}  disabled={!override}
                      className="text-sm border rounded-lg px-2 py-1.5 disabled:bg-gray-50 disabled:text-gray-400 outline-none" style={{ borderColor: "#DCE6E2" }} />
                    <span className="text-gray-400 text-xs">→</span>
                    <input type="time" value={hours[day].close} onChange={e => updateDay(day,"close",e.target.value)} disabled={!override}
                      className="text-sm border rounded-lg px-2 py-1.5 disabled:bg-gray-50 disabled:text-gray-400 outline-none" style={{ borderColor: "#DCE6E2" }} />
                  </div>
                ) : (
                  <span className="text-sm text-gray-400 italic">{t("horaires.closedAllDay")}</span>
                )}
              </div>
            ))}
          </div>

          <div className="p-4 border-t flex justify-end gap-3" style={{ borderColor: "#DCE6E2" }}>
            <SecondaryButton>{t("common.cancel")}</SecondaryButton>
            <PrimaryButton onClick={handleSave} disabled={!override}>
              {saved ? t("horaires.savedBtn") : t("horaires.saveBtn")}
            </PrimaryButton>
          </div>
        </Card>

        <Card>
          <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora flex items-center gap-2" style={{ color: "#0D3B36" }}>
              <Clock size={16} style={{ color: "#0F9B8E" }} /> {t("horaires.deliveryWindow")}
            </h2>
          </div>
          <div className="p-4 space-y-4">
            <p className="text-sm text-gray-500">{t("horaires.deliveryDesc")}</p>
            <div>
              <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>{t("horaires.deliveryStart")}</label>
              <input type="time" value={deliveryStart} onChange={e => setDeliveryStart(e.target.value)}
                className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2" }} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>{t("horaires.deliveryEnd")}</label>
              <input type="time" value={deliveryEnd} onChange={e => setDeliveryEnd(e.target.value)}
                className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2" }} />
            </div>
            <div className="p-4 rounded-xl text-center" style={{ background: "#e6f7f6" }}>
              <p className="text-xs text-gray-500 mb-1">{t("horaires.currentWindow")}</p>
              <p className="text-2xl font-bold font-sora" style={{ color: "#0F9B8E" }}>{deliveryStart} – {deliveryEnd}</p>
              <p className="text-xs text-gray-500 mt-1">{t("horaires.clientVisible")}</p>
            </div>
            <PrimaryButton onClick={handleSave} className="w-full justify-center">{t("horaires.apply")}</PrimaryButton>
          </div>
        </Card>
      </div>
    </div>
  );
}
