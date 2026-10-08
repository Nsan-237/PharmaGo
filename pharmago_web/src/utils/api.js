const API_BASE_URL =
  import.meta.env.VITE_API_URL || "https://pharmago-production-781f.up.railway.app/api";

const getAuthHeaders = () => {
  const token = localStorage.getItem("pharmago_token");
  return token ? { Authorization: `Bearer ${token}` } : {};
};

export const apiFetch = async (endpoint, options = {}) => {
  const headers = {
    "Content-Type": "application/json",
    ...getAuthHeaders(),
    ...options.headers,
  };

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers,
    });

    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || `HTTP error! Status: ${response.status}`);
    }
    return data;
  } catch (error) {
    console.warn(`API Error [${endpoint}]:`, error.message);
    throw error;
  }
};

// Auth API Methods
export const apiLogin = (email, password) =>
  apiFetch("/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });

export const apiRegister = (userData) =>
  apiFetch("/auth/register", {
    method: "POST",
    body: JSON.stringify(userData),
  });

export const apiGetProfile = () => apiFetch("/auth/me");

// Pharmacy API Methods
export const apiGetPharmacies = (params = {}) => {
  const query = new URLSearchParams(params).toString();
  return apiFetch(`/pharmacies?${query}`);
};

export const apiGetPharmacyById = (id) => apiFetch(`/pharmacies/${id}`);

// Inventory / Product API Methods
export const apiSearchProducts = (query = "") => apiFetch(`/products/search?q=${encodeURIComponent(query)}`);

export const apiAddProduct = (productData) =>
  apiFetch("/products", {
    method: "POST",
    body: JSON.stringify(productData),
  });

export const apiUpdateProduct = (id, productData) =>
  apiFetch(`/products/${id}`, {
    method: "PUT",
    body: JSON.stringify(productData),
  });

export const apiDeleteProduct = (id) =>
  apiFetch(`/products/${id}`, {
    method: "DELETE",
  });

// Prescriptions Queue API Methods
export const apiGetPrescriptionQueue = (params = {}) => {
  const query = new URLSearchParams(params).toString();
  return apiFetch(`/prescriptions/queue?${query}`);
};

export const apiVerifyPrescription = (id, data) =>
  apiFetch(`/prescriptions/${id}/verify`, {
    method: "PUT",
    body: JSON.stringify(data),
  });

// Orders API Methods
export const apiGetOrders = (params = {}) => {
  const query = new URLSearchParams(params).toString();
  return apiFetch(`/orders?${query}`);
};

export const apiUpdateOrderStatus = (id, statusData) =>
  apiFetch(`/orders/${id}/status`, {
    method: "PUT",
    body: JSON.stringify(statusData),
  });

// Admin Metrics API Methods
export const apiGetAdminMetrics = () => apiFetch("/admin/metrics");
export const apiApprovePharmacy = (id, isApproved) =>
  apiFetch(`/admin/pharmacies/${id}/approval`, {
    method: "PUT",
    body: JSON.stringify({ isApproved }),
  });

// Payment API Methods (MTN MoMo & Orange Money)
export const apiInitiatePayment = (orderId, amount, phone, provider) =>
  apiFetch("/payments/initiate", {
    method: "POST",
    body: JSON.stringify({ orderId, amount, phone, provider }),
  });

export const apiCheckPaymentStatus = (transactionId) => apiFetch(`/payments/status/${transactionId}`);

// Driver GPS Tracking API Methods
export const apiUpdateDriverLocation = (orderId, lat, lng) =>
  apiFetch("/tracking/location", {
    method: "POST",
    body: JSON.stringify({ orderId, lat, lng }),
  });

export const apiGetDriverLocation = (orderId) => apiFetch(`/tracking/location/${orderId}`);

// ── Admin Users CRUD ───────────────────────────────────────────────────────
export const apiGetUsers = (params = {}) => {
  const query = new URLSearchParams(params).toString();
  return apiFetch(`/admin/users?${query}`);
};

export const apiCreateUser = (userData) =>
  apiFetch("/admin/users", {
    method: "POST",
    body: JSON.stringify(userData),
  });

export const apiUpdateUser = (id, userData) =>
  apiFetch(`/admin/users/${id}`, {
    method: "PUT",
    body: JSON.stringify(userData),
  });

export const apiDeleteUser = (id) =>
  apiFetch(`/admin/users/${id}`, {
    method: "DELETE",
  });

// ── Admin Pharmacies CRUD ──────────────────────────────────────────────────
export const apiCreatePharmacy = (pharmacyData) =>
  apiFetch("/pharmacies", {
    method: "POST",
    body: JSON.stringify(pharmacyData),
  });

export const apiUpdatePharmacyFull = (id, pharmacyData) =>
  apiFetch(`/pharmacies/${id}`, {
    method: "PUT",
    body: JSON.stringify(pharmacyData),
  });

export const apiDeletePharmacy = (id) =>
  apiFetch(`/pharmacies/${id}`, {
    method: "DELETE",
  });

// ── Delivery Agent API ─────────────────────────────────────────────────────
export const apiGetAgentOrders = () => apiFetch("/agent/orders");

export const apiAcceptOrder = (id) =>
  apiFetch(`/agent/orders/${id}/accept`, { method: "PATCH" });

export const apiMarkDelivered = (id) =>
  apiFetch(`/agent/orders/${id}/deliver`, { method: "PATCH" });

export const apiGetAgentStats = () => apiFetch("/agent/stats");

// ── Status mapping helpers ──────────────────────────────────────────────────
// API returns uppercase (PENDING, CONFIRMED…) but UI uses fr-style keys
export const API_TO_UI_STATUS = {
  PENDING:          "en_attente",
  CONFIRMED:        "confirme",
  PREPARING:        "en_preparation",
  READY_FOR_PICKUP: "pret",
  IN_TRANSIT:       "en_route",
  DELIVERED:        "livree",
  CANCELLED:        "rejete",
};

export const UI_TO_API_STATUS = {
  en_attente:    "PENDING",
  confirme:      "CONFIRMED",
  en_preparation:"PREPARING",
  pret:          "READY_FOR_PICKUP",
  en_route:      "IN_TRANSIT",
  livree:        "DELIVERED",
  rejete:        "CANCELLED",
};

/** Normalize a raw API order to the shape the UI expects */
export const normalizeOrder = (o) => ({
  id:              o.orderNumber || o.id,
  _id:             o.id,
  orderId:         o.orderNumber || o.id,
  client:          o.patient?.fullName  || "—",
  phone:           o.patient?.phone     || "—",
  address:         o.deliveryAddress    || "",
  drugs:           (o.items || []).map(i => ({ name: i.productName, qty: i.quantity })),
  drugsSummary:    (o.items || []).map(i => `${i.productName} (x${i.quantity})`).join(", "),
  total:           o.totalAmount        || 0,
  type:            o.deliveryAddress    ? "livraison" : "retrait",
  status:          API_TO_UI_STATUS[o.status] || "en_attente",
  apiStatus:       o.status,
  hasPrescription: !!o.prescriptionId,
  pharmacy:        o.pharmacy?.name     || "—",
  pharmacyPhone:   o.pharmacy?.phone    || "—",
  pharmacyAddress: o.pharmacy?.address  || "—",
  pharmacyId:      o.pharmacyId,
  deliveryAgentId: o.deliveryAgentId    || null,
  deliveryAgentName: o.deliveryAgent?.fullName || "—",
  paymentMethod:   o.paymentMethod,
  paymentStatus:   o.paymentStatus,
  createdAt:       o.createdAt,
  updatedAt:       o.updatedAt,
});

