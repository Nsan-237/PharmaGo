import React, { useState, useEffect, useCallback } from "react";
import {
  CheckCircle,
  XCircle,
  Clock,
  AlertTriangle,
  FileText,
  Package,
  X,
  RefreshCw,
  Loader2,
} from "lucide-react";
import { useT, useLang } from "../../i18n/TranslationContext";
import { apiGetOrders, apiUpdateOrderStatus, normalizeOrder } from "../../utils/api";
import { useToast } from "../../components/shared/Toast";
import { timeAgo } from "../../utils/timeUtils";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card } from "../../components/shared/UI";

export default function CashierConfirmation() {
  const t = useT();
  const { lang } = useLang();
  const isFr = lang === "fr";
  const toast = useToast();

  const [orders, setOrders] = useState([]);
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [rejectReason, setRejectReason] = useState("");

  const fetchOrders = useCallback(
    async (silent = false) => {
      if (!silent) setLoading(true);
      else setRefreshing(true);
      try {
        const data = await apiGetOrders({ status: "PENDING" });
        const norm = (data.orders || []).map(normalizeOrder);
        setOrders(norm.filter((o) => o.status === "en_attente"));
      } catch (err) {
        if (!silent) {
          toast.error(
            isFr ? "Impossible de charger les commandes." : "Failed to load orders.",
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
    const interval = setInterval(() => fetchOrders(true), 30_000);
    return () => clearInterval(interval);
  }, [fetchOrders]);

  const confirm = async (id) => {
    const order = orders.find((o) => o.id === id || o._id === id);
    const dbId = order?._id || id;
    try {
      await apiUpdateOrderStatus(dbId, { status: "CONFIRMED" });
      setOrders((prev) => prev.filter((o) => o.id !== id && o._id !== id));
      if (order) {
        setHistory((prev) => [
          { ...order, status: "confirme", processedAt: new Date().toISOString() },
          ...prev,
        ]);
      }
      toast.success(
        isFr
          ? `Commande ${order?.id || id} confirmée avec succès.`
          : `Order ${order?.id || id} confirmed successfully.`,
        isFr ? "✅ Commande confirmée" : "✅ Order confirmed"
      );
    } catch (err) {
      toast.error(
        isFr ? "Échec de confirmation de la commande." : "Failed to confirm order.",
        "Error"
      );
    }
  };

  const openReject = (id) => {
    setRejectTarget(id);
    setRejectReason("");
  };

  const confirmReject = async () => {
    const id = rejectTarget;
    const order = orders.find((o) => o.id === id || o._id === id);
    const dbId = order?._id || id;
    try {
      await apiUpdateOrderStatus(dbId, {
        status: "CANCELLED",
        reason: rejectReason,
      });
      setOrders((prev) => prev.filter((o) => o.id !== id && o._id !== id));
      if (order) {
        setHistory((prev) => [
          { ...order, status: "rejete", processedAt: new Date().toISOString() },
          ...prev,
        ]);
      }
      toast.warning(
        isFr
          ? `Commande ${order?.id || id} rejetée.`
          : `Order ${order?.id || id} rejected.`,
        isFr ? "Commande rejetée" : "Order rejected"
      );
    } catch (err) {
      toast.error(
        isFr ? "Échec du rejet de la commande." : "Failed to reject order.",
        "Error"
      );
    }
    setRejectTarget(null);
  };

  return (
    <div>
      <PageHeader
        title={t("cashier.title")}
        subtitle={t("cashier.subtitle")}
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

      <div
        className="mb-6 p-4 rounded-xl flex items-start gap-3 border-l-4"
        style={{ background: "#FEF3DC", borderLeftColor: "#E8A33D" }}
      >
        <AlertTriangle size={20} style={{ color: "#E8A33D" }} className="shrink-0 mt-0.5" />
        <div>
          <p className="font-semibold text-sm" style={{ color: "#0D3B36" }}>
            {t("cashier.notice")}
          </p>
          <p className="text-sm text-gray-600 mt-0.5">{t("cashier.noticeDesc")}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="xl:col-span-2">
          <div className="flex items-center gap-3 mb-4">
            <h2 className="font-semibold font-sora" style={{ color: "#0D3B36" }}>
              {t("cashier.queue")}
            </h2>
            <span
              className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold text-white"
              style={{ background: "#E8A33D" }}
            >
              {orders.length} {t("cashier.pending")}
            </span>
          </div>

          {loading ? (
            <Card className="p-12 text-center flex flex-col items-center justify-center gap-3">
              <Loader2 size={36} className="animate-spin" style={{ color: "#0F9B8E" }} />
              <p className="text-gray-400 font-medium text-sm">
                {isFr ? "Chargement des commandes en attente…" : "Loading pending orders…"}
              </p>
            </Card>
          ) : orders.length === 0 ? (
            <Card className="p-12 text-center">
              <CheckCircle size={40} className="mx-auto mb-3" style={{ color: "#0F9B8E" }} />
              <p className="font-semibold font-sora" style={{ color: "#0D3B36" }}>
                {t("cashier.emptyQueue")}
              </p>
              <p className="text-sm text-gray-500 mt-1">{t("cashier.allProcessed")}</p>
            </Card>
          ) : (
            <div className="space-y-4">
              {orders.map((order) => (
                <Card key={order._id || order.id} className="overflow-hidden">
                  <div
                    className="p-4 border-b flex items-center justify-between"
                    style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className="w-8 h-8 rounded-lg flex items-center justify-center"
                        style={{ background: "#FEF3DC" }}
                      >
                        <Clock size={16} style={{ color: "#E8A33D" }} />
                      </div>
                      <div>
                        <p className="font-mono font-bold text-sm" style={{ color: "#0F9B8E" }}>
                          {order.id}
                        </p>
                        <p className="text-xs text-gray-400">{timeAgo(order.createdAt, lang)}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <span
                        className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                          order.type === "livraison"
                            ? "bg-blue-50 text-blue-700"
                            : "bg-gray-100 text-gray-600"
                        }`}
                      >
                        {order.type === "livraison" ? t("type.delivery") : t("type.pickup")}
                      </span>
                      {order.hasPrescription && (
                        <span className="text-xs px-2 py-0.5 rounded-full bg-purple-50 text-purple-700 font-medium flex items-center gap-1">
                          <FileText size={10} /> {t("cashier.rx")}
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="p-4">
                    <div className="flex items-start gap-4">
                      <div
                        className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold font-sora shrink-0"
                        style={{ background: "#0F9B8E" }}
                      >
                        {(order.client || "P")
                          .split(" ")
                          .map((n) => n[0])
                          .join("")
                          .slice(0, 2)
                          .toUpperCase()}
                      </div>
                      <div className="flex-1">
                        <p className="font-semibold" style={{ color: "#0D3B36" }}>
                          {order.client}
                        </p>
                        <p className="text-sm text-gray-400">{order.phone}</p>
                        {order.address && (
                          <p className="text-xs text-gray-400 mt-0.5">📍 {order.address}</p>
                        )}
                      </div>
                      <div className="text-right">
                        <p className="text-xs text-gray-400">{t("common.total")}</p>
                        <p className="text-xl font-bold font-sora" style={{ color: "#0D3B36" }}>
                          {order.total.toLocaleString()}
                        </p>
                        <p className="text-xs text-gray-400">FCFA</p>
                      </div>
                    </div>

                    <div className="mt-4 p-3 rounded-lg" style={{ background: "#F6F5EF" }}>
                      <p className="text-xs font-semibold text-gray-500 mb-2 flex items-center gap-1">
                        <Package size={12} /> {t("cashier.drugsRequested")}
                      </p>
                      <div className="space-y-1">
                        {order.drugs && order.drugs.length > 0 ? (
                          order.drugs.map((d, i) => (
                            <div key={i} className="flex items-center justify-between text-sm">
                              <span style={{ color: "#0D3B36" }}>{d.name}</span>
                              <span className="font-medium text-gray-600">x{d.qty}</span>
                            </div>
                          ))
                        ) : (
                          <p className="text-xs text-gray-400 italic">
                            {order.drugsSummary || (isFr ? "Médicaments sur ordonnance" : "Prescription items")}
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="mt-4 grid grid-cols-2 gap-3">
                      <button
                        onClick={() => confirm(order.id)}
                        className="flex items-center justify-center gap-2 py-3 rounded-xl text-white font-semibold text-sm transition-all hover:opacity-90 active:scale-95 shadow-sm"
                        style={{ background: "#0F9B8E" }}
                      >
                        <CheckCircle size={18} /> {t("cashier.confirm")}
                      </button>
                      <button
                        onClick={() => openReject(order.id)}
                        className="flex items-center justify-center gap-2 py-3 rounded-xl text-white font-semibold text-sm bg-red-500 hover:bg-red-600 transition-all active:scale-95"
                      >
                        <XCircle size={18} /> {t("cashier.rejectOrder")}
                      </button>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>

        <div>
          <h2 className="font-semibold font-sora mb-4" style={{ color: "#0D3B36" }}>
            {t("cashier.processedToday")}
          </h2>
          {history.length === 0 ? (
            <Card className="p-6 text-center">
              <p className="text-sm text-gray-400">{t("cashier.noneYet")}</p>
            </Card>
          ) : (
            <div className="space-y-3">
              {history.map((o) => (
                <Card key={o.id + o.processedAt} className="p-3">
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-mono text-sm font-semibold" style={{ color: "#0F9B8E" }}>
                      {o.id}
                    </span>
                    <StatusBadge status={o.status} />
                  </div>
                  <p className="text-sm font-medium" style={{ color: "#0D3B36" }}>
                    {o.client}
                  </p>
                  <p className="text-xs text-gray-400">{o.total.toLocaleString()} FCFA</p>
                </Card>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Reject reason modal */}
      {rejectTarget && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4 animate-fade-in"
          style={{ background: "rgba(13,59,54,0.4)", backdropFilter: "blur(4px)" }}
          onClick={() => setRejectTarget(null)}
        >
          <div
            className="bg-white rounded-2xl shadow-2xl w-full max-w-sm animate-fade-in-up"
            onClick={(e) => e.stopPropagation()}
          >
            <div
              className="p-5 border-b flex items-center justify-between"
              style={{ borderColor: "#DCE6E2" }}
            >
              <p className="font-bold font-sora" style={{ color: "#0D3B36" }}>
                {isFr ? "Rejeter cette commande" : "Reject this order"}
              </p>
              <button
                onClick={() => setRejectTarget(null)}
                className="p-1 rounded text-gray-400 hover:text-gray-600"
              >
                <X size={16} />
              </button>
            </div>
            <div className="p-5 space-y-4">
              <div
                className="flex items-center gap-2 p-3 rounded-lg"
                style={{ background: "#FEE2E2" }}
              >
                <AlertTriangle size={15} className="text-red-500 shrink-0" />
                <p className="text-sm text-red-700 font-medium">{rejectTarget}</p>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5" style={{ color: "#0D3B36" }}>
                  {isFr ? "Motif du rejet (optionnel)" : "Rejection reason (optional)"}
                </label>
                <textarea
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none resize-none transition-all"
                  style={{ borderColor: "#DCE6E2", background: "#FBFBF8" }}
                  placeholder={
                    isFr
                      ? "Ex: stock insuffisant, ordonnance invalide..."
                      : "E.g. out of stock, invalid prescription..."
                  }
                />
              </div>
              <div className="flex gap-3">
                <button
                  onClick={() => setRejectTarget(null)}
                  className="flex-1 py-2.5 rounded-lg border font-semibold text-sm hover:bg-gray-50 transition-all"
                  style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}
                >
                  {isFr ? "Annuler" : "Cancel"}
                </button>
                <button
                  onClick={confirmReject}
                  className="flex-1 py-2.5 rounded-lg text-white font-semibold text-sm bg-red-500 hover:bg-red-600 transition-all active:scale-95"
                >
                  {isFr ? "Confirmer le rejet" : "Confirm rejection"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
