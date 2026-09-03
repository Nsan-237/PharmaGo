import React from "react";
import { Users, Building2, ShoppingBag, TrendingUp, AlertTriangle } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { chartData, pharmacies, disputes } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { StatCard, PageHeader, Card } from "../../components/shared/UI";

const CustomTooltip = ({ active, payload, label, t }) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-white border rounded-xl p-3 shadow-lg text-sm" style={{ borderColor: "#DCE6E2" }}>
      <p className="font-semibold mb-1" style={{ color: "#0D3B36" }}>{label}</p>
      <p style={{ color: "#0F9B8E" }}>{t("platDash.orders")}: <strong>{payload[0]?.value}</strong></p>
      <p style={{ color: "#E8A33D" }}>{t("common.revenue")}: <strong>{(payload[1]?.value||0).toLocaleString()} FCFA</strong></p>
    </div>
  );
};

export default function PlatformDashboard() {
  const t = useT();
  const totalRevenue = chartData.reduce((s,d) => s+d.revenu, 0);
  const totalOrders  = chartData.reduce((s,d) => s+d.commandes, 0);

  return (
    <div>
      <PageHeader title={t("platDash.title")} subtitle={t("platDash.subtitle")} />

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <StatCard title={t("platDash.totalUsers")}   value="8"                                              icon={Users}      color="#2563eb" bg="#dbeafe" trend={{ positive: true, value: t("platDash.usersTrend") }} />
        <StatCard title={t("platDash.partners")}     value={pharmacies.filter(p=>p.approved).length}        icon={Building2}  color="#0F9B8E" bg="#e6f7f6" subtitle={`${pharmacies.filter(p=>!p.approved).length} ${t("platDash.partnersSub")}`} />
        <StatCard title={t("platDash.orders7d")}     value={totalOrders}                                     icon={ShoppingBag}color="#E8A33D" bg="#FEF3DC" trend={{ positive: true, value: t("platDash.ordersTrend") }} />
        <StatCard title={t("platDash.revenue7d")}    value={`${(totalRevenue/1000).toFixed(0)}k FCFA`}       icon={TrendingUp} color="#16a34a" bg="#dcfce7" trend={{ positive: true, value: t("platDash.revenueTrend") }} />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <Card className="xl:col-span-2">
          <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("platDash.activity")}</h2>
          </div>
          <div className="p-4" style={{ height: 280 }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#DCE6E2" />
                <XAxis dataKey="date" tick={{ fontSize: 11, fill: "#6b7280" }} />
                <YAxis yAxisId="left"  tick={{ fontSize: 11, fill: "#6b7280" }} />
                <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 11, fill: "#6b7280" }} />
                <Tooltip content={<CustomTooltip t={t} />} />
                <Line yAxisId="left"  type="monotone" dataKey="commandes" stroke="#0F9B8E" strokeWidth={2.5} dot={{ r: 4, fill: "#0F9B8E" }} />
                <Line yAxisId="right" type="monotone" dataKey="revenu"    stroke="#E8A33D" strokeWidth={2.5} dot={{ r: 4, fill: "#E8A33D" }} strokeDasharray="5 3" />
              </LineChart>
            </ResponsiveContainer>
            <div className="flex gap-4 justify-center mt-2">
              <span className="flex items-center gap-1.5 text-xs text-gray-500"><span className="w-4 h-0.5 bg-primary inline-block" />{t("platDash.orders")}</span>
              <span className="flex items-center gap-1.5 text-xs text-gray-500"><span className="w-4 h-0.5 bg-amber-400 inline-block" />{t("common.revenue")} (FCFA)</span>
            </div>
          </div>
        </Card>

        <div className="space-y-6">
          <Card>
            <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
              <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("platDash.topPharmacies")}</h2>
            </div>
            <div className="p-3 space-y-2">
              {pharmacies.filter(p=>p.approved).sort((a,b)=>b.orders-a.orders).slice(0,4).map((p,i) => (
                <div key={p.id} className="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50">
                  <span className="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold text-white" style={{ background: i===0 ? "#E8A33D" : "#0F9B8E" }}>
                    {i+1}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate" style={{ color: "#0D3B36" }}>{p.name}</p>
                    <p className="text-xs text-gray-400">{p.orders} {t("platDash.orders")} · {p.city}</p>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          <Card>
            <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
              <h2 className="font-semibold font-sora flex items-center gap-2" style={{ color: "#0D3B36" }}>
                <AlertTriangle size={15} className="text-red-500" /> {t("platDash.recentDisputes")}
              </h2>
            </div>
            <div className="p-3 space-y-2">
              {disputes.slice(0,3).map(d => (
                <div key={d.id} className="p-2 rounded-lg" style={{ background: "#F6F5EF" }}>
                  <div className="flex items-center justify-between mb-0.5">
                    <span className="text-xs font-mono font-semibold" style={{ color: "#0F9B8E" }}>{d.id}</span>
                    <StatusBadge status={d.status} />
                  </div>
                  <p className="text-xs text-gray-600 truncate">{d.reason}</p>
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
