import React, { useState, useEffect, useCallback } from "react";
import {
  MapPin,
  Package,
  ChevronRight,
  RefreshCw,
  Loader2,
  CheckCircle,
  Phone,
  Building2,
} from "lucide-react";
import { useT, useLang } from "../../i18n/TranslationContext";
import {
  apiGetAgentOrders,
  apiAcceptOrder,
  apiMarkDelivered,
  normalizeOrder,
} from "../../utils/api";
import { useToast } from "../../components/shared/Toast";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card } from "../../components/shared/UI";

export default function AgentDeliveries() {
  const t = useT();
  const { lang } = useLang();
  const isFr = lang === "fr";
  const toast = useToast();

  const [availableOrders, setAvailableOrders] = useState([]);
  const [assignedOrders, setAssignedOrders] = useState([]);
  const [deliveredOrders, setDeliveredOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [tab, setTab] = useState("assignee");
  const [actionLoadingId, setActionLoadingId] = useState(null);

  const fetchOrders = useCallback(
    async (silent = false) => {
      if (!silent) setLoading(true);
      else setRefreshing(true);
      try {
        const data = await apiGetAgentOrders();
        setAvailableOrders((data.available || []).map(normalizeOrder));
        setAssignedOrders((data.assigned || []).map(normalizeOrder));
        setDeliveredOrders((data.delivered || []).map(normalizeOrder));
      } catch (err) {
        if (!silent) {
          toast.error(
            isFr
              ? "Impossible de charger les livraisons."
              : "Failed to load deliveries.",
            isFr ? "Erreur réseau" : "Network error"
          );
        }
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [isFr]
  );

  useEffect(() => {
    fetchOrders();
    const interval = setInterval(() => fetchOrders(true), 20_000);
    return () => clearInterval(interval);
  }, [fetchOrders]);

  const handleAccept = async (order) => {
    const dbId = order._id || order.id;
    try {
      setActionLoadingId(dbId);
      await apiAcceptOrder(dbId);
      toast.success(
        isFr
          ? `Commande ${order.id} acceptée ! En route vers la pharmacie.`
          : `Order ${order.id} accepted! En route to pick up.`,
        isFr ? "Livraison acceptée" : "Delivery accepted"
      );
      await fetchOrders(true);
      setTab("en_route");
    } catch (err) {
      toast.error(
        err.message ||
          (isFr
            ? "Impossible d'accepter cette commande."
            : "Failed to accept order."),
        "Error"
      );
    } finally {
      setActionLoadingId(null);
    }
  };

  const handleDeliver = async (order) => {
    const dbId = order._id || order.id;
    try {
      setActionLoadingId(dbId);
      await apiMarkDelivered(dbId);
      toast.success(
        isFr
          ? `Commande ${order.id} marquée comme livrée !`
          : `Order ${order.id} marked as delivered!`,
        isFr ? "Livraison terminée" : "Delivered"
      );
      await fetchOrders(true);
      setTab("livree");
    } catch (err) {
      toast.error(
        err.message ||
          (isFr
            ? "Impossible de finaliser la livraison."
            : "Failed to finalize delivery."),
        "Error"
      );
    } finally {
      setActionLoadingId(null);
    }
  };

  const tabs = [
    {
      key: "assignee",
      label: isFr
        ? `Disponibles & En attente (${availableOrders.length})`
        : `Available & Pending (${availableOrders.length})`,
      count: availableOrders.length,
      data: availableOrders,
    },
    {
      key: "en_route",
      label: isFr
        ? `Mes livraisons en cours (${assignedOrders.length})`
        : `My active deliveries (${assignedOrders.length})`,
      count: assignedOrders.length,
      data: assignedOrders,
    },
    {
      key: "livree",
      label: isFr
        ? `Livrées (${deliveredOrders.length})`
        : `Delivered (${deliveredOrders.length})`,
      count: deliveredOrders.length,
      data: deliveredOrders,
    },
  ];

  const currentTabData =
    tab === "assignee"
      ? availableOrders
      : tab === "en_route"
      ? assignedOrders
      : deliveredOrders;

  return (
    <div>
      <PageHeader
        title={t("agent.title")}
        subtitle={
          isFr
            ? `Espace Livreur · ${availableOrders.length + assignedOrders.length} courses disponibles/actives`
            : `Driver Portal · ${availableOrders.length + assignedOrders.length} active/available deliveries`
        }
        action={
          <button
            onClick={() => fetchOrders(true)}
            disabled={refreshing}
            className="flex items-center gap-2 px-3 py-2 rounded-xl border text-sm font-medium hover:bg-gray-50 transition-all"
            style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
          >
            <RefreshCw size={14} className={refreshing ? "animate-spin" : ""} />
            {isFr ? "Actualiser" : "Refresh"}
          </button>
        }
      />

      {/* Tabs */}
      <div className="flex gap-2 mb-5 overflow-x-auto pb-1">
        {tabs.map((tb) => (
          <button
            key={tb.key}
            onClick={() => setTab(tb.key)}
            className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all shrink-0 ${
              tab === tb.key
                ? "text-white shadow-sm"
                : "bg-white text-gray-600 border hover:bg-gray-50"
            }`}
            style={
              tab === tb.key
                ? { background: "#0F9B8E" }
                : { borderColor: "#DCE6E2" }
            }
          >
            {tb.label}
          </button>
        ))}
      </div>

      {loading ? (
        <Card className="p-16 text-center flex flex-col items-center justify-center gap-3">
          <Loader2 size={36} className="animate-spin" style={{ color: "#0F9B8E" }} />
          <p className="text-gray-400 font-medium text-sm">
            {isFr ? "Recherche des livraisons en cours…" : "Fetching deliveries…"}
          </p>
        </Card>
      ) : currentTabData.length === 0 ? (
        <Card className="p-12 text-center">
          <Package size={36} className="mx-auto mb-3 text-gray-300" />
          <p className="text-gray-500 font-medium">
            {tab === "assignee"
              ? isFr
                ? "Aucune nouvelle commande en attente de livraison"
                : "No pending orders available for pickup"
              : tab === "en_route"
              ? isFr
                ? "Vous n'avez aucune livraison en cours"
                : "You have no active deliveries"
              : isFr
              ? "Aucune livraison terminée aujourd'hui"
              : "No delivered orders yet"}
          </p>
          <p className="text-xs text-gray-400 mt-1">
            {isFr
              ? "Les commandes passées par les clients apparaîtront ici dès validation."
              : "Customer orders will appear here automatically once confirmed."}
          </p>
        </Card>
      ) : (
        <div className="space-y-4">
          {currentTabData.map((d) => (
            <Card key={d._id || d.id} className="p-4 overflow-hidden border">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                    style={{ background: "#e6f7f6" }}
                  >
                    <Package size={18} style={{ color: "#0F9B8E" }} />
                  </div>
                  <div>
                    <p className="font-mono font-bold text-sm" style={{ color: "#0F9B8E" }}>
                      {d.id}
                    </p>
                    <p className="text-xs text-gray-400">
                      {d.paymentMethod === "CASH" ? "💵 Paiement à la livraison (Cash)" : "💳 Déjà payé (Mobile Money)"}
                    </p>
                  </div>
                </div>
                <StatusBadge status={d.status} />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4">
                <div>
                  <p className="text-xs text-gray-400 mb-0.5">{t("agent.colClient")}</p>
                  <p className="text-sm font-semibold" style={{ color: "#0D3B36" }}>
                    {d.client}
                  </p>
                  {d.phone && d.phone !== "—" && (
                    <p className="text-xs text-gray-500 flex items-center gap-1 mt-0.5">
                      <Phone size={11} /> {d.phone}
                    </p>
                  )}
                </div>
                <div>
                  <p className="text-xs text-gray-400 mb-0.5">{t("agent.colPharmacy")}</p>
                  <p className="text-sm font-semibold flex items-center gap-1" style={{ color: "#0D3B36" }}>
                    <Building2 size={13} className="text-[#0F9B8E]" /> {d.pharmacy}
                  </p>
                  {d.pharmacyAddress && d.pharmacyAddress !== "—" && (
                    <p className="text-xs text-gray-500 mt-0.5">📍 {d.pharmacyAddress}</p>
                  )}
                </div>
                <div className="sm:col-span-2">
                  <p className="text-xs text-gray-400 mb-0.5 flex items-center gap-1">
                    <MapPin size={11} /> {t("agent.colAddress")}
                  </p>
                  <p className="text-sm font-medium" style={{ color: "#0D3B36" }}>
                    {d.address || (isFr ? "Non renseignée" : "Not specified")}
                  </p>
                </div>
                <div className="sm:col-span-2">
                  <p className="text-xs text-gray-400 mb-0.5">{t("agent.colDrugs")}</p>
                  <p className="text-sm text-gray-600">
                    {d.drugs && d.drugs.length > 0
                      ? d.drugs.map((i) => `${i.name} (x${i.qty})`).join(", ")
                      : d.drugsSummary || "Articles sous ordonnance"}
                  </p>
                </div>
              </div>

              <div
                className="flex items-center justify-between border-t pt-3"
                style={{ borderColor: "#DCE6E2" }}
              >
                <div>
                  <p className="text-xs text-gray-400">{isFr ? "Montant à encaisser" : "Total amount"}</p>
                  <p className="font-bold font-sora text-base" style={{ color: "#0D3B36" }}>
                    {(d.total || 0).toLocaleString()} FCFA
                  </p>
                </div>

                {tab === "assignee" && (
                  <button
                    onClick={() => handleAccept(d)}
                    disabled={actionLoadingId === (d._id || d.id)}
                    className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-white text-sm font-semibold hover:opacity-90 active:scale-95 transition-all shadow-sm"
                    style={{ background: "#0F9B8E" }}
                  >
                    {actionLoadingId === (d._id || d.id) ? (
                      <Loader2 size={14} className="animate-spin" />
                    ) : (
                      <>
                        {t("agent.accept")} <ChevronRight size={14} />
                      </>
                    )}
                  </button>
                )}

                {tab === "en_route" && (
                  <button
                    onClick={() => handleDeliver(d)}
                    disabled={actionLoadingId === (d._id || d.id)}
                    className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-white text-sm font-semibold bg-green-600 hover:bg-green-700 active:scale-95 transition-all shadow-sm"
                  >
                    {actionLoadingId === (d._id || d.id) ? (
                      <Loader2 size={14} className="animate-spin" />
                    ) : (
                      <>
                        <CheckCircle size={15} /> {t("agent.markDelivered")}
                      </>
                    )}
                  </button>
                )}

                {tab === "livree" && (
                  <span className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-green-50 text-green-700 font-semibold text-xs">
                    <CheckCircle size={14} /> {isFr ? "Livraison effectuée" : "Delivered"}
                  </span>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
