# PharmaGo Cameroon — Project Architecture & Implementation Guide
> **Version:** 1.0.0 (Production-Ready Architecture)  
> **Ecosystem:** Mobile App (Flutter) • Web Portal (React/Vite) • Backend API (Node.js/Express) • Database (PostgreSQL/Supabase) • Payments (CamPay Mobile Money) • AI (Google Gemini 1.5 Flash)

---

## 1. Executive Summary & Vision

**PharmaGo** is a comprehensive digital health and pharmacy ecosystem designed for Cameroon and Central Africa. It solves three critical problems:
1. **Pharmacy Locator & On-Call Finder (*Pharmacies de Garde*)**: Allows patients to locate verified open pharmacies in real-time in cities like Yaoundé, Douala, Bafoussam, Garoua, and Limbe with GPS distance and turn-by-turn route calculations.
2. **Prescription & Over-The-Counter Medication Delivery**: Enables patients to search available stock, upload prescriptions, and order medications delivered directly to their doorstep via motorcycle couriers in ~30 minutes.
3. **Seamless Mobile Money Payments**: Direct integration with **MTN Mobile Money** and **Orange Money Cameroon** via CamPay with interactive USSD PIN approval on the customer's phone.
4. **Intelligent AI Health Assistant (PharmAI)**: Powered by Google Gemini 1.5 Flash, assisting users in French and English with symptom analysis, OTC medication suggestions, and photo analysis (rash, packaging, wound).

---

## 2. High-Level System Architecture

```mermaid
graph TD
    subgraph Client Layer
        A[📱 Flutter Mobile App<br/>Patients & Delivery Couriers]
        B[💻 React Web Portal<br/>Super Admin, Pharmacy Admin, Cashier]
    end

    subgraph API & Backend Layer
        C[🌐 Express.js API Server<br/>Port 5000]
        D[🛡️ Auth & Security<br/>JWT + Bcrypt Hash]
        E[💳 Payment Service<br/>Campay Gateway Proxy]
    end

    subgraph Data & Cloud Services
        F[(🗄️ PostgreSQL Database<br/>Supabase Cloud)]
        G[🤖 Google Gemini 1.5 Flash<br/>Multimodal AI Assistant]
        H[📱 MTN MoMo & Orange Money<br/>USSD Push Payment SIM]
    end

    A -->|REST API / HTTPS| C
    B -->|REST API / HTTPS| C
    C --> D
    C --> E
    C -->|Prisma ORM| F
    A -->|Gemini SDK & Proxy| G
    E -->|HTTPS Direct / Webhooks| H
```

---

## 3. The 3 System Components

### 3.1. `pharmago_app` (Flutter Mobile & Web)
- **Directory:** `/pharmago_app`
- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod 2.x
- **Navigation:** GoRouter
- **Features:**
  - **Splash & Onboarding:** Dynamic bilingual onboarding (FR/EN) with 3 realistic healthcare visual cards (`onboarding_find_pharmacy.jpg`, `onboarding_order_medicine.jpg`, `onboarding_fast_delivery.jpg`).
  - **Turn-by-Turn Route Navigation:** Integrated OpenStreetMap (`flutter_map`) calculating real distance and travel time to nearby pharmacies.
  - **Order & Prescription Flow:** Prescriptions upload with camera/gallery (`image_picker`), order tracking with status timeline (`PENDING` ➔ `CONFIRMED` ➔ `IN_TRANSIT` ➔ `DELIVERED`).
  - **Campay Mobile Money Checkout:** Dedicated modal bottom sheet displaying MTN and Orange logos, USSD instructions (`*126#` / `#150#`), automatic status polling loop, and success confirmation.
  - **Floating AI Chatbot (PharmAI):** Floating action button with online status pulse dot, accessible from any screen for immediate medical assistance.
  - **Mobile Delivery Mode:** Built specifically for motorcycle delivery couriers on the road with turn-by-turn GPS route guidance, one-tap phone calls to the customer, and delivery validation.

### 3.2. `pharmago_server` (Node.js & Express REST API)
- **Directory:** `/pharmago_server`
- **Port:** `5000`
- **Database ORM:** Prisma ORM connected to PostgreSQL on Supabase.
- **Key Modules:**
  - `src/routes/authRoutes.js`: User registration, phone/email login, password hashing with `bcryptjs`, and JWT token issuance.
  - `src/routes/pharmacyRoutes.js`: Pharmacy directory, GPS radius filtering, on-call status (*de garde*), medication inventory lookup.
  - `src/routes/orderRoutes.js`: Order lifecycle management, prescription attachment, live status updates.
  - `src/routes/paymentRoutes.js`: CamPay payment initiation (`/api/payment/initiate`), payment status polling (`/api/payment/status/:reference`), and webhook listeners.
  - `src/routes/adminRoutes.js`: System metrics, platform commission tracking, pharmacy approval pipeline.

### 3.3. `pharmago_web` (React / Vite Management Portal)
- **Directory:** `/pharmago_web`
- **Port:** `3000`
- **Framework:** React 18, Vite, Lucide Icons, Tailwind / Vanilla CSS.
- **Dedicated Role-Based Portals:**
  - **Super Admin Platform:** Platform health, total transaction volume, commissions, pharmacy verification, dispute resolution.
  - **Pharmacy Admin (Gérant):** Stock management, drug catalog, pricing, daily pharmacy earnings, staff accounts.
  - **Cashier (Caissier):** Dedicated Point-Of-Sale (POS) counter interface to validate incoming pickups, dispense medications, and record counter cash payments.

---

## 4. Multi-Role Access Control Model

| Role | Interface | Primary Responsibilities |
| :--- | :--- | :--- |
| **`PATIENT`** | Mobile App | Search pharmacies, consult PharmAI, order medications, pay via MoMo/OM, track delivery. |
| **`DELIVERY_AGENT` (Livreur)** | **Mobile App** | Receive delivery requests, navigate to pharmacy & client via GPS, call/WhatsApp client, confirm delivery. |
| **`CASHIER` (Caissier)** | Web Portal | Validate orders at counter, verify prescriptions, register in-store cash payments. |
| **`PHARMACY_ADMIN` (Gérant)** | Web Portal | Manage medication catalog, stock levels, sales reports, pharmacy profile, cashier accounts. |
| **`PLATFORM_ADMIN` (Super Admin)**| Web Portal | Platform oversight, add/verify pharmacies, manage commissions, inspect CamPay transactions. |

---

## 5. Payment Pipeline (CamPay Mobile Money)

```
[ Patient taps "Payer avec MTN / Orange" ]
                 │
                 ▼
[ 1. POST /api/payment/initiate ]
     Sends: { amount: 10, phone: "2376...", description: "Commande #..." }
                 │
                 ▼
[ 2. CamPay API dispatches USSD Push ]
     - MTN: Push prompt *126# directly to user's SIM
     - Orange: Push prompt #150# directly to user's SIM
                 │
                 ▼
[ 3. Patient enters Mobile Money PIN on their phone ]
                 │
                 ▼
[ 4. Mobile App polls /api/payment/status/:reference ]
     - Status transitions from PENDING ➔ SUCCESSFUL
     - Order marked as PAID
     - Client redirected to /order-confirmed
```

---

## 6. PharmAI: Google Gemini 1.5 Flash Medical Assistant

### How PharmAI Works:
1. **Multimodal Analysis:** Accepts text input or captured photos (rashes, wounds, medication packaging labels).
2. **Cultural & Local Context:** Understands common pathologies in Cameroon (Malaria / Paludisme, Typhoïde, Grippe, Céphalées, etc.).
3. **Structured Response Format:**
   - **Empathetic Acknowledgment:** Repeats the observed symptoms.
   - **Potential Causes:** Suggests non-definitive medical possibilities.
   - **Over-The-Counter (OTC) Relief Options:** Mentions standard relief products available at local pharmacies without prescription (e.g. Paracétamol, Soluté de Réhydratation, Antiacide).
   - **Urgent Signs & Triage:** Clearly highlights critical warning signs that require immediate hospital attention.
   - **Ethical Medical Disclaimer:** Reminds the user that AI does not replace a licensed medical doctor or pharmacist.

---

## 7. Database Schema (Prisma PostgreSQL)

Key models defined in `pharmago_server/prisma/schema.prisma`:
- **`User`**: `id`, `email`, `phone`, `passwordHash`, `fullName`, `role` (`PATIENT`, `PHARMACY_ADMIN`, `CASHIER`, `DELIVERY_AGENT`, `PLATFORM_ADMIN`).
- **`Pharmacy`**: `id`, `name`, `slug`, `city`, `address`, `latitude`, `longitude`, `phone`, `isOnDuty` (*de garde*), `rating`.
- **`PharmacyStaff`**: Links `User` to `Pharmacy` with specific staff roles.
- **`Medication`**: `id`, `name`, `category`, `price`, `requiresPrescription`, `imageUrl`, `pharmacyId`, `inStock`.
- **`Order`**: `id`, `orderNumber`, `patientId`, `pharmacyId`, `deliveryAgentId`, `status`, `totalAmount`, `prescriptionUrl`, `deliveryAddress`.
- **`Payment`**: `id`, `orderId`, `reference`, `operator` (`MTN_MOMO`, `ORANGE_MONEY`, `CASH`), `amount`, `status`.

---

## 8. Environment Variables (`.env`)

Located in `pharmago_server/.env`:
```env
PORT=5000
DATABASE_URL="postgresql://postgres.cqvbereqxeoebthqjvlg:Qwertyui%40237cam@aws-1-eu-west-3.pooler.supabase.com:5432/postgres"
JWT_SECRET="pharmago_secret_jwt_key_2026_cameroon"

# Campay Mobile Money Credentials
CAMPAY_APP_USERNAME="0PF1nsPiIbZ-2q8lVqKWp6GNA7D5gTP6BEbLI9Xcg40MZjXsdiYLSL6MGgwDxk-p1RaF0hPAYqBNoS7SgHVrMw"
CAMPAY_APP_PASSWORD="uCMRsxtqzL5cq-qskcrHeEzA81Yn99DPDTE7HLaAqLSTGrM6-o-fghVeas3o9MEJ8Pi17Mbo8_eRdPCK13rpnw"
CAMPAY_PERMANENT_TOKEN="J23uzKJW7dvG+RZ3/ZDX_3kRM96E3rXo~HNsEnFv"
CAMPAY_ENV="demo"

# Google Gemini AI API Key
GEMINI_API_KEY="AIzaSyDkeFqPBV_bCduN1sdlWjnSiswZ-GU7pug"
```

---

## 9. How to Run & Test the Ecosystem

### Start the Backend Server:
```powershell
cd pharmago_server
npm install
npm run dev
# Running on http://localhost:5000
```

### Start the Web Admin Portal:
```powershell
cd pharmago_web
npm install
npm run dev -- --port 3000
# Running on http://localhost:3000
```

### Start the Flutter Mobile / Web App:
```powershell
cd pharmago_app
flutter pub get
flutter run -d chrome --web-port 9000 --dart-define=GEMINI_API_KEY=AIzaSyDkeFqPBV_bCduN1sdlWjnSiswZ-GU7pug
# Running on http://localhost:9000
```

---

## 10. Operational Guidelines & Future Roadmap
1. **SMS Gateway Integration:** When ready to send real SMS OTPs instead of passwords, connect **Camoo SMS Cameroon** or **Twilio** to the `/api/auth/otp/send` route.
2. **Go Live with CamPay:** To transition from Sandbox to real money payments in Cameroon, switch `CAMPAY_ENV="production"` in `pharmago_server/.env` after verifying business documents with the CamPay team.
3. **Live Geolocation Tracking:** WebSocket integration between the delivery courier's mobile app and the client's tracking screen for live map pin movements during transit.
