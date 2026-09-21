const API_BASE_URL = "http://localhost:5000/api";

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


