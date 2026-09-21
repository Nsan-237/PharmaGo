import React, { createContext, useContext, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import DashboardLayout from "./components/shared/DashboardLayout";
import { TranslationProvider } from "./i18n/TranslationContext";

// Pharmacy Admin
import PharmaDashboard from "./features/pharmacyAdmin/Dashboard";
import PharmaStock from "./features/pharmacyAdmin/Stock";
import PharmaOrders from "./features/pharmacyAdmin/Orders";
import PharmaAgents from "./features/pharmacyAdmin/Agents";
import PharmaHoraires from "./features/pharmacyAdmin/Horaires";
import PharmSettings from "./features/pharmacyAdmin/PharmSettings";
import MessagingPage from "./features/shared/Messaging";

// Cashier
import CashierConfirmation from "./features/cashier/OrderConfirmation";
import CashierPrescriptions from "./features/cashier/Prescriptions";
import CashierHistory from "./features/cashier/History";

// Delivery Agent
import AgentDeliveries from "./features/deliveryAgent/Deliveries";
import AgentHistory from "./features/deliveryAgent/AgentHistory";

// Platform Admin
import PlatformDashboard from "./features/platformAdmin/Dashboard";
import PlatformUsers from "./features/platformAdmin/Users";
import PlatformPharmacies from "./features/platformAdmin/Pharmacies";
import PlatformOrders from "./features/platformAdmin/PlatformOrders";
import PlatformDisputes from "./features/platformAdmin/Disputes";
import PlatformReports from "./features/platformAdmin/Reports";

// Auth
import Login from "./features/auth/Login";

const RoleContext = createContext();
export const useRole = () => useContext(RoleContext);

function getInitialRole() {
  try {
    const userStr = localStorage.getItem("pharmago_user");
    if (userStr) {
      const u = JSON.parse(userStr);
      if (u.role === "PLATFORM_ADMIN") return "platform_admin";
      if (u.role === "PHARMACY_ADMIN") return "pharmacy_admin";
      if (u.role === "CASHIER") return "cashier";
      if (u.role === "DELIVERY_AGENT") return "delivery_agent";
    }
  } catch (_) {}
  return "pharmacy_admin";
}

function RootRedirect() {
  const token = localStorage.getItem("pharmago_token");
  const { role } = useRole();
  if (!token) return <Navigate to="/login" replace />;
  if (role === "platform_admin") return <Navigate to="/platform-admin/dashboard" replace />;
  if (role === "cashier") return <Navigate to="/cashier/confirmation" replace />;
  if (role === "delivery_agent") return <Navigate to="/agent/deliveries" replace />;
  return <Navigate to="/pharmacy-admin/dashboard" replace />;
}

function App() {
  const [role, setRole] = useState(getInitialRole);

  return (
    <TranslationProvider>
      <RoleContext.Provider value={{ role, setRole }}>
        <BrowserRouter>
        <Routes>
          <Route path="/" element={<RootRedirect />} />
          <Route path="/login" element={<Login />} />
          
          {/* Pharmacy Admin */}
          <Route path="/pharmacy-admin" element={<DashboardLayout />}>
            <Route path="dashboard" element={<PharmaDashboard />} />
            <Route path="stock" element={<PharmaStock />} />
            <Route path="orders" element={<PharmaOrders />} />
            <Route path="agents" element={<PharmaAgents />} />
            <Route path="horaires" element={<PharmaHoraires />} />
            <Route path="messaging" element={<MessagingPage />} />
            <Route path="settings" element={<PharmSettings />} />
          </Route>

          {/* Cashier */}
          <Route path="/cashier" element={<DashboardLayout />}>
            <Route path="confirmation" element={<CashierConfirmation />} />
            <Route path="prescriptions" element={<CashierPrescriptions />} />
            <Route path="history" element={<CashierHistory />} />
            <Route path="messaging" element={<MessagingPage />} />
          </Route>

          {/* Delivery Agent */}
          <Route path="/agent" element={<DashboardLayout />}>
            <Route path="deliveries" element={<AgentDeliveries />} />
            <Route path="history" element={<AgentHistory />} />
          </Route>

          {/* Platform Admin */}
          <Route path="/platform-admin" element={<DashboardLayout />}>
            <Route path="dashboard" element={<PlatformDashboard />} />
            <Route path="users" element={<PlatformUsers />} />
            <Route path="pharmacies" element={<PlatformPharmacies />} />
            <Route path="orders" element={<PlatformOrders />} />
            <Route path="disputes" element={<PlatformDisputes />} />
            <Route path="reports" element={<PlatformReports />} />
            <Route path="messaging" element={<MessagingPage />} />
            <Route path="settings" element={<PharmSettings />} />
          </Route>
        </Routes>
        </BrowserRouter>
      </RoleContext.Provider>
    </TranslationProvider>
  );
}

export default App;
