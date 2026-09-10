import React, { useState, useEffect } from "react";
import { Package, ShoppingBag, Clock, AlertTriangle } from "lucide-react";
import { drugs as mockDrugs, orders as mockOrders } from "../../mockData/index";
import { apiGetOrders, apiSearchProducts } from "../../utils/api";
import { useT } from "../../i18n/TranslationContext";
import StatusBadge from "../../components/shared/StatusBadge";
import { StatCard, PageHeader, Card, TableWrapper, Th, Td } from "../../components/shared/UI";

export default function PharmaDashboard() {
  const t = useT();
  const [orders, setOrders] = useState(mockOrders);
  const [drugs, setDrugs] = useState(mockDrugs);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    async function loadLiveData() {
      try {
        setIsLoading(true);
        const [ordersRes, productsRes] = await Promise.allSettled([
          apiGetOrders(),
          apiSearchProducts(""),
        ]);

        if (ordersRes.status === "fulfilled" && ordersRes.value.orders) {
          const formattedOrders = ordersRes.value.orders.map((o) => ({
            id: o.orderNumber || o.id,
            client: o.patient?.fullName || "Patient",
            phone: o.patient?.phone || "+237",
            drugs: o.items ? o.items.map((i) => ({ name: i.productName, qty: i.quantity })) : [],
            total: o.totalAmount,
            status: o.status.toLowerCase(),
            type: o.deliveryAddress ? "livraison" : "retrait",
            createdAt: o.createdAt,
          }));
          setOrders(formattedOrders);
        }

        if (productsRes.status === "fulfilled" && productsRes.value.products) {
          const formattedDrugs = productsRes.value.products.map((p) => ({
            id: p.id,
            name: p.name,
            quantity: p.stockQuantity,
            status: p.stockQuantity > 20 ? "en_stock" : p.stockQuantity > 0 ? "stock_faible" : "rupture",
          }));
          setDrugs(formattedDrugs);
        }
      } catch (err) {
        console.log("Using fallback mock data for dashboard");
      } finally {
        setIsLoading(false);
      }
    }

    loadLiveData();
  }, []);

  const todayOrders = orders.length;
  const enAttente = orders.filter((o) => o.status === "en_attente" || o.status === "pending").length;
  const stockFaible = drugs.filter((d) => d.status === "stock_faible" || d.quantity <= 10).length;

  return (
    <div>
      <PageHeader title={t("pharmaDash.title")} subtitle={t("pharmaDash.subtitle")} />

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <StatCard title={t("pharmaDash.inStock")}     value={drugs.filter(d=>d.status==="en_stock").length} icon={Package}       color="#0F9B8E" bg="#e6f7f6" subtitle={`${drugs.length} ${t("pharmaDash.inStockSub")}`} />
        <StatCard title={t("pharmaDash.todayOrders")} value={todayOrders}                                   icon={ShoppingBag}   color="#2563eb" bg="#dbeafe" trend={{ positive: true, value: t("pharmaDash.vsYesterday") }} />
        <StatCard title={t("pharmaDash.pending")}     value={enAttente}                                     icon={Clock}         color="#E8A33D" bg="#FEF3DC" subtitle={t("pharmaDash.pendingSub")} />
        <StatCard title={t("pharmaDash.lowStock")}    value={stockFaible}                                   icon={AlertTriangle} color="#dc2626" bg="#fee2e2" subtitle={t("pharmaDash.lowStockSub")} />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <Card className="xl:col-span-2">
          <div className="p-4 border-b flex items-center justify-between" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("pharmaDash.recentOrders")}</h2>
            <span className="text-xs text-gray-400">{t("common.today")}</span>
          </div>
          <TableWrapper>
            <thead>
              <tr>
                <Th>{t("pharmaDash.orderNo")}</Th>
                <Th>{t("pharmaDash.client")}</Th>
                <Th>{t("pharmaDash.drugs")}</Th>
                <Th>{t("common.total")}</Th>
                <Th>{t("common.status")}</Th>
                <Th>{t("common.type")}</Th>
              </tr>
            </thead>
            <tbody>
              {orders.slice(0,6).map(o => (
                <tr key={o.id} className="hover:bg-gray-50 transition-colors">
                  <Td><span className="font-mono font-medium text-primary">{o.id}</span></Td>
                  <Td>
                    <div>
                      <p className="font-medium" style={{ color: "#0D3B36" }}>{o.client}</p>
                      <p className="text-xs text-gray-400">{o.phone}</p>
                    </div>
                  </Td>
                  <Td><p className="text-xs text-gray-600">{o.drugs.map(d=>`${d.name} x${d.qty}`).join(", ")}</p></Td>
                  <Td><span className="font-semibold">{o.total.toLocaleString()} FCFA</span></Td>
                  <Td><StatusBadge status={o.status} /></Td>
                  <Td>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${o.type === "livraison" ? "bg-blue-50 text-blue-700" : "bg-gray-100 text-gray-600"}`}>
                      {o.type === "livraison" ? t("type.delivery") : t("type.pickup")}
                    </span>
                  </Td>
                </tr>
              ))}
            </tbody>
          </TableWrapper>
        </Card>

        <Card>
          <div className="p-4 border-b" style={{ borderColor: "#DCE6E2" }}>
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>{t("pharmaDash.stockAlerts")}</h2>
          </div>
          <div className="p-4 space-y-3">
            {drugs.filter(d => d.status !== "en_stock").map(d => (
              <div key={d.id} className="flex items-center justify-between p-3 rounded-lg" style={{ background: "#F6F5EF" }}>
                <div>
                  <p className="text-sm font-medium" style={{ color: "#0D3B36" }}>{d.name}</p>
                  <p className="text-xs text-gray-400">{d.quantity} {t("pharmaDash.unitsLeft")}</p>
                </div>
                <StatusBadge status={d.status} />
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
