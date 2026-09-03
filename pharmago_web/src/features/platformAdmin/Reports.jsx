import React from "react";
import { Download, FileText } from "lucide-react";
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";
import { chartData, pharmacies } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { exportToCSV, exportToPDF } from "../../utils/exportUtils";
import { PageHeader, Card } from "../../components/shared/UI";

const categoryData = [
  { name: "Analgésiques", value: 320 },
  { name: "Antibiotiques", value: 180 },
  { name: "Antipaludéens", value: 250 },
  { name: "Vitamines",     value: 140 },
  { name: "Autres",        value: 95  },
];
const COLORS = ["#0F9B8E","#E8A33D","#2563eb","#16a34a","#dc2626"];

export default function PlatformReports() {
  const t = useT();

  const handleExportCSV = () => {
    const headers = [t("common.date"), t("platDash.orders"), `${t("common.revenue")} (FCFA)`];
    const rows = chartData.map(d => [d.date, d.commandes, d.revenu]);
    exportToCSV(headers, rows, `pharmago_analytics_${new Date().toISOString().slice(0,10)}`);
  };

  const handleExportPDF = () => {
    const headers = [t("common.date"), t("platDash.orders"), `${t("common.revenue")} (FCFA)`];
    const rows = chartData.map(d => [d.date, d.commandes, `${d.revenu.toLocaleString()} FCFA`]);
    exportToPDF(t("reports.title"), headers, rows, `pharmago_analytics_${new Date().toISOString().slice(0,10)}`);
  };

  return (
    <div>
      <PageHeader
        title={t("reports.title")}
        subtitle={t("reports.subtitle")}
        action={
          <div className="flex gap-2">
            <button
              onClick={handleExportCSV}
              className="flex items-center gap-1.5 px-3 py-2 rounded-lg border text-sm font-medium hover:bg-gray-50 transition-colors bg-white"
              style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
            >
              <Download size={14} /> CSV
            </button>
            <button
              onClick={handleExportPDF}
              className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-white text-sm font-medium hover:opacity-90 transition-colors shadow-sm"
              style={{ background: "#0F9B8E" }}
            >
              <FileText size={14} /> {t("export.downloadReport")}
            </button>
          </div>
        }
      />

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6 mb-6">
        <Card>
          <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("reports.orderVolume")}</h2>
          </div>
          <div className="p-4" style={{ height: 220 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#DCE6E2" />
                <XAxis dataKey="date" tick={{ fontSize: 10, fill: "#6b7280" }} />
                <YAxis tick={{ fontSize: 10, fill: "#6b7280" }} />
                <Tooltip formatter={(v) => [v, t("platDash.orders")]} />
                <Bar dataKey="commandes" fill="#0F9B8E" radius={[4,4,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card>
          <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("reports.totalRevenue")}</h2>
          </div>
          <div className="p-4" style={{ height: 220 }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#DCE6E2" />
                <XAxis dataKey="date" tick={{ fontSize: 10, fill: "#6b7280" }} />
                <YAxis tick={{ fontSize: 10, fill: "#6b7280" }} tickFormatter={v => `${v/1000}k`} />
                <Tooltip formatter={(v) => [`${v.toLocaleString()} FCFA`, t("common.revenue")]} />
                <Line type="monotone" dataKey="revenu" stroke="#E8A33D" strokeWidth={2.5} dot={{ r: 4 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <Card>
          <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("reports.byCategory")}</h2>
          </div>
          <div className="p-4 flex items-center gap-6" style={{ height: 220 }}>
            <ResponsiveContainer width="50%" height="100%">
              <PieChart>
                <Pie data={categoryData} cx="50%" cy="50%" outerRadius={70} dataKey="value" strokeWidth={0}>
                  {categoryData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <div className="flex-1 space-y-2">
              {categoryData.map((c, i) => (
                <div key={c.name} className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full shrink-0" style={{ background: COLORS[i] }} />
                  <span className="text-xs text-gray-600 flex-1">{c.name}</span>
                  <span className="text-xs font-semibold" style={{ color: "#0D3B36" }}>{c.value}</span>
                </div>
              ))}
            </div>
          </div>
        </Card>

        <Card>
          <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("reports.pharmacyRanking")}</h2>
          </div>
          <div className="p-4 space-y-3">
            {pharmacies.filter(p=>p.approved).sort((a,b)=>b.revenue-a.revenue).map((p,i) => (
              <div key={p.id}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium" style={{ color: "#0D3B36" }}>{p.name}</span>
                  <span className="text-xs font-semibold" style={{ color: "#0F9B8E" }}>{p.revenue.toLocaleString()} FCFA</span>
                </div>
                <div className="w-full bg-gray-100 rounded-full h-1.5">
                  <div className="h-1.5 rounded-full" style={{ width: `${(p.revenue/1500000)*100}%`, background: i===0 ? "#E8A33D" : "#0F9B8E" }} />
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
