import React from "react";
import { orders } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function CashierHistory() {
  const t = useT();
  const processed = orders.filter(o => o.status !== "en_attente");
  return (
    <div>
      <PageHeader title={t("cashierHist.title")} subtitle={`${processed.length} ${t("cashierHist.subtitle")}`} />
      <Card>
        <TableWrapper>
          <thead>
            <tr>
              <Th>{t("cashierHist.colOrderNo")}</Th>
              <Th>{t("cashierHist.colClient")}</Th>
              <Th>{t("cashierHist.colDrugs")}</Th>
              <Th>{t("cashierHist.colTotal")}</Th>
              <Th>{t("cashierHist.colStatus")}</Th>
              <Th>{t("cashierHist.colType")}</Th>
            </tr>
          </thead>
          <tbody>
            {processed.map(o => (
              <tr key={o.id} className="hover:bg-gray-50">
                <Td><span className="font-mono font-semibold" style={{ color: "#0F9B8E" }}>{o.id}</span></Td>
                <Td><p className="font-medium" style={{ color: "#0D3B36" }}>{o.client}</p></Td>
                <Td><p className="text-xs text-gray-600">{o.drugs.map(d=>`${d.name} x${d.qty}`).join(", ")}</p></Td>
                <Td><span className="font-semibold">{o.total.toLocaleString()} FCFA</span></Td>
                <Td><StatusBadge status={o.status} /></Td>
                <Td><span className="text-xs">{o.type==="livraison" ? t("type.delivery") : t("type.pickup")}</span></Td>
              </tr>
            ))}
          </tbody>
        </TableWrapper>
      </Card>
    </div>
  );
}
