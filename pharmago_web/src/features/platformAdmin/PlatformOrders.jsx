import React from "react";
import { orders } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function PlatformOrders() {
  const t = useT();
  return (
    <div>
      <PageHeader title={t("platOrders.title")} subtitle={`${orders.length} ${t("platOrders.subtitle")}`} />
      <Card>
        <TableWrapper>
          <thead>
            <tr>
              <Th>{t("platOrders.colOrderNo")}</Th>
              <Th>{t("platOrders.colClient")}</Th>
              <Th>{t("platOrders.colDrugs")}</Th>
              <Th>{t("platOrders.colTotal")}</Th>
              <Th>{t("platOrders.colType")}</Th>
              <Th>{t("platOrders.colStatus")}</Th>
              <Th>{t("platOrders.colDate")}</Th>
            </tr>
          </thead>
          <tbody>
            {orders.map(o => (
              <tr key={o.id} className="hover:bg-gray-50">
                <Td><span className="font-mono font-semibold" style={{ color: "#0F9B8E" }}>{o.id}</span></Td>
                <Td>
                  <p className="font-medium" style={{ color: "#0D3B36" }}>{o.client}</p>
                  <p className="text-xs text-gray-400">{o.phone}</p>
                </Td>
                <Td><p className="text-xs text-gray-600 max-w-[160px] truncate">{o.drugs.map(d=>`${d.name} x${d.qty}`).join(", ")}</p></Td>
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
