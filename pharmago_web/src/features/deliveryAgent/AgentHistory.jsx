import React from "react";
import { deliveries } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function AgentHistory() {
  const t = useT();
  const done = deliveries.filter(d => d.status === "livree");
  return (
    <div>
      <PageHeader title={t("agentHist.title")} subtitle={`${done.length} ${t("agentHist.subtitle")}`} />
      <Card>
        <TableWrapper>
          <thead>
            <tr>
              <Th>{t("agentHist.colId")}</Th>
              <Th>{t("agentHist.colClient")}</Th>
              <Th>{t("agentHist.colAddress")}</Th>
              <Th>{t("agentHist.colDrugs")}</Th>
              <Th>{t("agentHist.colTotal")}</Th>
              <Th>{t("agentHist.colStatus")}</Th>
            </tr>
          </thead>
          <tbody>
            {done.map(d => (
              <tr key={d.id} className="hover:bg-gray-50">
                <Td><span className="font-mono font-semibold" style={{ color: "#0F9B8E" }}>{d.id}</span></Td>
                <Td><span className="font-medium" style={{ color: "#0D3B36" }}>{d.client}</span></Td>
                <Td><span className="text-xs text-gray-500">{d.address}</span></Td>
                <Td><span className="text-xs text-gray-600">{d.drugs}</span></Td>
                <Td><span className="font-semibold">{d.total.toLocaleString()} FCFA</span></Td>
                <Td><StatusBadge status={d.status} /></Td>
              </tr>
            ))}
          </tbody>
        </TableWrapper>
      </Card>
    </div>
  );
}
