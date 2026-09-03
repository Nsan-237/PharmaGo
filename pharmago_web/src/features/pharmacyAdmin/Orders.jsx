import React, { useState } from "react";
import { Download, FileText } from "lucide-react";
import { orders as initialOrders } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { exportToCSV, exportToPDF } from "../../utils/exportUtils";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function PharmaOrders() {
  const t = useT();
  const [orders] = useState(initialOrders);
  const [filter, setFilter] = useState("all");

  const tabs = [
    { key: "all",       labelKey: "orders.tabAll" },
    { key: "en_attente",labelKey: "orders.tabPending" },
    { key: "confirme",  labelKey: "orders.tabConfirmed" },
    { key: "en_route",  labelKey: "orders.tabEnRoute" },
    { key: "livree",    labelKey: "orders.tabDelivered" },
    { key: "rejete",    labelKey: "orders.tabRejected" },
  ];

  const filtered = filter === "all" ? orders : orders.filter(o => o.status === filter);

  // Export helpers
  const headers = [t("orders.colOrderNo"), t("orders.colClient"), t("orders.colDrugs"), t("orders.colTotal"), t("orders.colType"), t("orders.colStatus"), t("orders.colDate")];
  const toRows = (list) => list.map(o => [
    o.id, o.client,
    o.drugs.map(d => `${d.name} x${d.qty}`).join(", "),
    `${o.total.toLocaleString()} FCFA`,
    o.type === "livraison" ? t("type.deliveryShort") : t("type.pickupShort"),
    t(`status.${o.status}`),
    new Date(o.createdAt).toLocaleDateString(),
  ]);
  const handleCSV = () => exportToCSV(headers, toRows(filtered), `pharmago_orders_${new Date().toISOString().slice(0,10)}`);
  const handlePDF = () => exportToPDF(t("orders.title"), headers, toRows(filtered), `pharmago_orders_${new Date().toISOString().slice(0,10)}`);

  return (
    <div>
      <PageHeader title={t("orders.title")} subtitle={`${orders.length} ${t("orders.subtitle")}`} />

      <div className="flex items-center gap-2 mb-5 overflow-x-auto pb-1">
        <div className="flex gap-2 flex-1">
          {tabs.map(tab => (
            <button key={tab.key} onClick={() => setFilter(tab.key)}
              className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all
                ${filter === tab.key ? "text-white" : "bg-white text-gray-600 border hover:bg-gray-50"}`}
              style={filter === tab.key ? { background: "#0F9B8E" } : { borderColor: "#DCE6E2" }}
            >
              {t(tab.labelKey)} {(filter === tab.key || tab.key === "all") ? `(${filtered.length})` : ""}
            </button>
          ))}
        </div>
        <button onClick={handleCSV}
          className="flex items-center gap-1.5 px-3 py-2 rounded-lg border text-sm font-medium hover:bg-gray-50 transition-colors shrink-0"
          style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}>
          <Download size={14} /> CSV
        </button>
        <button onClick={handlePDF}
          className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-white text-sm font-medium hover:opacity-90 transition-colors shrink-0"
          style={{ background: "#0F9B8E" }}>
          <FileText size={14} /> PDF
        </button>
      </div>

      <Card>
        <TableWrapper>
          <thead>
            <tr>
              <Th>{t("orders.colOrderNo")}</Th>
              <Th>{t("orders.colClient")}</Th>
              <Th>{t("orders.colDrugs")}</Th>
              <Th>{t("orders.colTotal")}</Th>
              <Th>{t("orders.colType")}</Th>
              <Th>{t("orders.colStatus")}</Th>
              <Th>{t("orders.colDate")}</Th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(o => (
              <tr key={o.id} className="hover:bg-gray-50 transition-colors">
                <Td><span className="font-mono font-semibold" style={{ color: "#0F9B8E" }}>{o.id}</span></Td>
                <Td>
                  <p className="font-medium" style={{ color: "#0D3B36" }}>{o.client}</p>
                  <p className="text-xs text-gray-400">{o.phone}</p>
                </Td>
                <Td><p className="text-xs text-gray-600 max-w-[180px] truncate">{o.drugs.map(d=>`${d.name} x${d.qty}`).join(", ")}</p></Td>
                <Td><span className="font-semibold">{o.total.toLocaleString()} FCFA</span></Td>
                <Td>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${o.type==="livraison" ? "bg-blue-50 text-blue-700" : "bg-gray-100 text-gray-600"}`}>
                    {o.type==="livraison" ? t("type.delivery") : t("type.pickup")}
                  </span>
                </Td>
                <Td><StatusBadge status={o.status} /></Td>
                <Td><span className="text-xs text-gray-400">{new Date(o.createdAt).toLocaleDateString()}</span></Td>
              </tr>
            ))}
          </tbody>
        </TableWrapper>
      </Card>
    </div>
  );
}
