// src/mockData/index.js

export const pharmacies = [
  { id: 1, name: "Pharmacie du Centre", address: "Rue de la Réunification, Douala", phone: "+237 233 42 15 80", status: "active", approved: true, orders: 124, revenue: 1450000, rating: 4.8, city: "Douala" },
  { id: 2, name: "Pharmacie Akwa", address: "Boulevard de la Liberté, Akwa, Douala", phone: "+237 233 43 22 10", status: "active", approved: true, orders: 89, revenue: 980000, rating: 4.6, city: "Douala" },
  { id: 3, name: "Pharmacie Bali", address: "Carrefour Bali, Douala", phone: "+237 233 40 88 55", status: "suspended", approved: true, orders: 43, revenue: 420000, rating: 4.1, city: "Douala" },
  { id: 4, name: "Pharmacie Mvog-Ada", address: "Mvog-Ada, Yaoundé", phone: "+237 222 23 11 60", status: "active", approved: true, orders: 67, revenue: 730000, rating: 4.5, city: "Yaoundé" },
  { id: 5, name: "Pharmacie Essos", address: "Quartier Essos, Yaoundé", phone: "+237 222 31 44 90", status: "active", approved: false, orders: 0, revenue: 0, rating: 0, city: "Yaoundé" },
  { id: 6, name: "Pharmacie Nouvelle Déido", address: "Deido, Douala", phone: "+237 233 41 77 20", status: "active", approved: true, orders: 102, revenue: 1120000, rating: 4.7, city: "Douala" },
];

export const drugs = [
  { id: 1, name: "Paracétamol 500mg", category: "Analgésique", quantity: 450, price: 500, status: "en_stock", requiresPrescription: false },
  { id: 2, name: "Amoxicilline 500mg", category: "Antibiotique", quantity: 80, price: 2500, status: "stock_faible", requiresPrescription: true },
  { id: 3, name: "Ibuprofène 400mg", category: "Anti-inflammatoire", quantity: 200, price: 800, status: "en_stock", requiresPrescription: false },
  { id: 4, name: "Metronidazole 250mg", category: "Antibiotique", quantity: 0, price: 1200, status: "rupture", requiresPrescription: true },
  { id: 5, name: "Chloroquine 100mg", category: "Antipaludéen", quantity: 320, price: 600, status: "en_stock", requiresPrescription: true },
  { id: 6, name: "Vitamine C 500mg", category: "Vitamines", quantity: 25, price: 1000, status: "stock_faible", requiresPrescription: false },
  { id: 7, name: "ORS Pédiatrique", category: "Pédiatrie", quantity: 150, price: 350, status: "en_stock", requiresPrescription: false },
  { id: 8, name: "Cotrimoxazole 960mg", category: "Antibiotique", quantity: 90, price: 900, status: "en_stock", requiresPrescription: true },
  { id: 9, name: "Tramadol 100mg", category: "Analgésique", quantity: 12, price: 3500, status: "stock_faible", requiresPrescription: true },
  { id: 10, name: "Amlodipine 5mg", category: "Cardiovasculaire", quantity: 180, price: 1500, status: "en_stock", requiresPrescription: true },
];

export const orders = [
  { id: "CMD-2401", client: "Marie Ngono", phone: "+237 677 34 21 09", drugs: [{ name: "Paracétamol 500mg", qty: 2 }, { name: "Vitamine C 500mg", qty: 1 }], total: 2000, status: "en_attente", type: "livraison", address: "Bonapriso, Douala", createdAt: "2026-08-27T08:30:00", hasPrescription: false },
  { id: "CMD-2402", client: "Jean-Paul Mbeki", phone: "+237 655 12 88 43", drugs: [{ name: "Amoxicilline 500mg", qty: 1 }], total: 2500, status: "confirme", type: "retrait", address: "", createdAt: "2026-08-27T09:15:00", hasPrescription: true },
  { id: "CMD-2403", client: "Fatima Bello", phone: "+237 699 45 67 23", drugs: [{ name: "Ibuprofène 400mg", qty: 3 }, { name: "ORS Pédiatrique", qty: 2 }], total: 3100, status: "en_route", type: "livraison", address: "Makepe, Douala", createdAt: "2026-08-27T10:00:00", hasPrescription: false },
  { id: "CMD-2404", client: "Paul Atangana", phone: "+237 677 88 12 54", drugs: [{ name: "Chloroquine 100mg", qty: 2 }], total: 1200, status: "livree", type: "livraison", address: "Omnisport, Yaoundé", createdAt: "2026-08-26T14:20:00", hasPrescription: true },
  { id: "CMD-2405", client: "Sophie Mendo", phone: "+237 655 33 91 77", drugs: [{ name: "Cotrimoxazole 960mg", qty: 1 }], total: 900, status: "rejete", type: "retrait", address: "", createdAt: "2026-08-26T11:45:00", hasPrescription: true },
  { id: "CMD-2406", client: "Alain Tchamba", phone: "+237 699 22 55 88", drugs: [{ name: "Amlodipine 5mg", qty: 1 }, { name: "Paracétamol 500mg", qty: 3 }], total: 3000, status: "en_attente", type: "livraison", address: "Logpom, Douala", createdAt: "2026-08-27T11:00:00", hasPrescription: false },
  { id: "CMD-2407", client: "Cécile Fouda", phone: "+237 677 65 44 31", drugs: [{ name: "Tramadol 100mg", qty: 1 }], total: 3500, status: "en_attente", type: "retrait", address: "", createdAt: "2026-08-27T11:20:00", hasPrescription: true },
  { id: "CMD-2408", client: "Sam Samuel", phone: "+237 670 12 34 56", drugs: [{ name: "Paracétamol 500mg", qty: 2 }, { name: "Vitamine C 1000mg", qty: 1 }], total: 2500, status: "en_attente", type: "livraison", address: "Bastos, Yaoundé", createdAt: "2026-09-21T11:30:00", hasPrescription: false },
];

export const users = [
  { id: 1, name: "Marie Ngono", email: "marie.ngono@gmail.com", phone: "+237 677 34 21 09", role: "client", status: "actif", joinedAt: "2026-03-15" },
  { id: 2, name: "Dr. Emmanuel Nkoa", email: "e.nkoa@pharmadu centre.cm", phone: "+237 655 78 90 12", role: "pharmacien", status: "actif", joinedAt: "2026-01-10" },
  { id: 3, name: "Roger Kamdem", email: "r.kamdem@pharmago.cm", phone: "+237 699 11 22 33", role: "agent_livraison", status: "actif", joinedAt: "2026-05-20" },
  { id: 4, name: "Jean-Paul Mbeki", email: "jp.mbeki@outlook.com", phone: "+237 655 12 88 43", role: "client", status: "actif", joinedAt: "2026-04-02" },
  { id: 5, name: "Fatima Bello", email: "f.bello@yahoo.fr", phone: "+237 699 45 67 23", role: "client", status: "suspendu", joinedAt: "2026-02-28" },
  { id: 6, name: "Christelle Owono", email: "c.owono@pharmacieakwa.cm", phone: "+237 233 43 22 10", role: "admin_pharmacie", status: "actif", joinedAt: "2026-01-05" },
  { id: 7, name: "Patrick Essomba", email: "p.essomba@pharmago.cm", phone: "+237 677 55 66 77", role: "agent_livraison", status: "actif", joinedAt: "2026-06-14" },
  { id: 8, name: "Aissatou Diallo", email: "a.diallo@gmail.com", phone: "+237 655 44 33 22", role: "client", status: "actif", joinedAt: "2026-07-19" },
];

export const deliveries = [
  { id: "LIV-501", orderId: "CMD-2403", client: "Fatima Bello", address: "Makepe, Douala", drugs: "Ibuprofène x3, ORS Péd. x2", total: 3100, status: "en_route", assignedAt: "2026-08-27T10:15:00", pharmacy: "Pharmacie du Centre" },
  { id: "LIV-502", orderId: "CMD-2401", client: "Marie Ngono", address: "Bonapriso, Douala", drugs: "Paracétamol x2, Vit. C x1", total: 2000, status: "assignee", assignedAt: "2026-08-27T11:05:00", pharmacy: "Pharmacie Akwa" },
  { id: "LIV-503", orderId: "CMD-2406", client: "Alain Tchamba", address: "Logpom, Douala", drugs: "Amlodipine x1, Paracétamol x3", total: 3000, status: "assignee", assignedAt: "2026-08-27T11:25:00", pharmacy: "Pharmacie Bali" },
  { id: "LIV-504", orderId: "CMD-2404", client: "Paul Atangana", address: "Omnisport, Yaoundé", drugs: "Chloroquine x2", total: 1200, status: "livree", assignedAt: "2026-08-26T14:35:00", pharmacy: "Pharmacie Mvog-Ada" },
];

export const agents = [
  { id: 1, name: "Roger Kamdem", phone: "+237 699 11 22 33", status: "disponible", deliveriesToday: 5, zone: "Douala Centre" },
  { id: 2, name: "Patrick Essomba", phone: "+237 677 55 66 77", status: "en_livraison", deliveriesToday: 3, zone: "Akwa / Bonapriso" },
  { id: 3, name: "Eric Nyamsi", phone: "+237 655 88 99 00", status: "disponible", deliveriesToday: 2, zone: "Makepe / Logpom" },
  { id: 4, name: "Bernadette Ngo", phone: "+237 699 77 44 55", status: "hors_ligne", deliveriesToday: 0, zone: "Deido / Ndog-Bong" },
];

export const disputes = [
  { id: "LIT-101", orderId: "CMD-2402", client: "Jean-Paul Mbeki", pharmacy: "Pharmacie Akwa", reason: "Médicament incorrect livré", status: "ouvert", createdAt: "2026-08-27T10:00:00", priority: "haute" },
  { id: "LIT-102", orderId: "CMD-2404", client: "Paul Atangana", pharmacy: "Pharmacie Mvog-Ada", reason: "Livraison non reçue", status: "en_cours", createdAt: "2026-08-26T16:00:00", priority: "moyenne" },
  { id: "LIT-103", orderId: "CMD-2398", client: "Aissatou Diallo", pharmacy: "Pharmacie du Centre", reason: "Prix incorrect facturé", status: "resolu", createdAt: "2026-08-25T09:00:00", priority: "faible" },
  { id: "LIT-104", orderId: "CMD-2395", client: "Sophie Mendo", pharmacy: "Pharmacie Nouvelle Déido", reason: "Retard de livraison excessif", status: "ouvert", createdAt: "2026-08-24T14:30:00", priority: "moyenne" },
];

export const chartData = [
  { date: "21 Août", commandes: 42, revenu: 385000 },
  { date: "22 Août", commandes: 58, revenu: 520000 },
  { date: "23 Août", commandes: 35, revenu: 298000 },
  { date: "24 Août", commandes: 71, revenu: 642000 },
  { date: "25 Août", commandes: 63, revenu: 575000 },
  { date: "26 Août", commandes: 89, revenu: 810000 },
  { date: "27 Août", commandes: 76, revenu: 694000 },
];

export const prescriptions = [
  { id: "ORD-301", client: "Fatima Bello", drug: "Amoxicilline 500mg", uploadedAt: "2026-08-27T09:00:00", status: "en_attente", imageUrl: "https://placehold.co/300x200/e8f5e9/0F9B8E?text=Ordonnance" },
  { id: "ORD-302", client: "Paul Atangana", drug: "Chloroquine 100mg", uploadedAt: "2026-08-27T10:30:00", status: "en_attente", imageUrl: "https://placehold.co/300x200/e8f5e9/0F9B8E?text=Ordonnance" },
  { id: "ORD-303", client: "Cécile Fouda", drug: "Tramadol 100mg", uploadedAt: "2026-08-27T11:20:00", status: "verifie", imageUrl: "https://placehold.co/300x200/e8f5e9/0F9B8E?text=Ordonnance" },
];
