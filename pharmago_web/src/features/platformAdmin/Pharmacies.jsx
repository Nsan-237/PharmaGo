import React, { useState } from "react";
import { CheckCircle, XCircle, Phone, MapPin } from "lucide-react";
import { pharmacies as initialPharmacies } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function PlatformPharmacies() {
  const t = useT();
  const [pharmacies, setPharmacies] = useState(initialPharmacies);

  const approve       = (id) => setPharmacies(prev => prev.map(p => p.id===id ? {...p,approved:true,status:"active"} : p));
  const toggleSuspend = (id) => setPharmacies(prev => prev.map(p => p.id===id ? {...p,status:p.status==="active"?"suspended":"active"} : p));

  const pending = pharmacies.filter(p => !p.approved);
  const active  = pharmacies.filter(p => p.approved);

  return (
    <div>
      <PageHeader
        title={t("pharmacies.title")}
        subtitle={`${pharmacies.length} ${t("pharmacies.subtitle")} · ${pending.length} ${t("pharmacies.pending")}`}
      />

      {pending.length > 0 && (
        <div className="mb-6">
          <h2 className="font-semibold font-sora mb-3 flex items-center gap-2" style={{ color: "#0D3B36" }}>
            <span className="w-2 h-2 rounded-full bg-amber-400" /> {t("pharmacies.pendingSection")} ({pending.length})
          </h2>
          <div className="space-y-3">
            {pending.map(p => (
              <div key={p.id} className="bg-white rounded-xl border p-4 flex items-center gap-4" style={{ borderColor: "#E8A33D", borderLeftWidth: 4 }}>
                <div className="flex-1">
                  <p className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{p.name}</p>
                  <p className="text-sm text-gray-500 flex items-center gap-1 mt-0.5"><MapPin size={12}/>{p.address}</p>
                  <p className="text-sm text-gray-500 flex items-center gap-1 mt-0.5"><Phone size={12}/>{p.phone}</p>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => approve(p.id)} className="flex items-center gap-2 px-4 py-2 rounded-lg text-white text-sm font-semibold" style={{ background: "#0F9B8E" }}>
                    <CheckCircle size={15} /> {t("common.approve")}
                  </button>
                  <button className="flex items-center gap-2 px-4 py-2 rounded-lg text-white text-sm font-semibold bg-red-500">
                    <XCircle size={15} /> {t("common.reject")}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      <Card>
        <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
          <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("pharmacies.active")}</h2>
        </div>
        <TableWrapper>
          <thead>
            <tr>
              <Th>{t("pharmacies.colPharmacy")}</Th>
              <Th>{t("pharmacies.colCity")}</Th>
              <Th>{t("pharmacies.colPhone")}</Th>
              <Th>{t("pharmacies.colOrders")}</Th>
              <Th>{t("pharmacies.colRevenue")}</Th>
              <Th>{t("pharmacies.colStatus")}</Th>
              <Th>{t("pharmacies.colAction")}</Th>
            </tr>
          </thead>
          <tbody>
            {active.map(p => (
              <tr key={p.id} className="hover:bg-gray-50">
                <Td>
                  <p className="font-medium" style={{ color: "#0D3B36" }}>{p.name}</p>
                  <p className="text-xs text-gray-400">{p.address}</p>
                </Td>
                <Td><span className="text-sm">{p.city}</span></Td>
                <Td><span className="text-sm text-gray-600">{p.phone}</span></Td>
                <Td><span className="font-semibold">{p.orders}</span></Td>
                <Td><span className="font-semibold">{p.revenue.toLocaleString()} FCFA</span></Td>
                <Td><StatusBadge status={p.status} /></Td>
                <Td>
                  <button onClick={() => toggleSuspend(p.id)}
                    className={`text-xs px-3 py-1.5 rounded-lg font-medium ${p.status==="active" ? "bg-red-50 text-red-600 hover:bg-red-100" : "bg-green-50 text-green-600 hover:bg-green-100"}`}>
                    {p.status==="active" ? t("common.suspend") : t("common.reactivate")}
                  </button>
                </Td>
              </tr>
            ))}
          </tbody>
        </TableWrapper>
      </Card>
    </div>
  );
}
