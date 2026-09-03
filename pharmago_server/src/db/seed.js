import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Seeding PharmaGo Database...");

  // Clean existing tables
  await prisma.deliveryLog.deleteMany();
  await prisma.message.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.prescription.deleteMany();
  await prisma.product.deleteMany();
  await prisma.pharmacyStaff.deleteMany();
  await prisma.pharmacy.deleteMany();
  await prisma.user.deleteMany();

  const hashedPassword = await bcrypt.hash("password123", 10);

  // 1. Create Users
  const patient = await prisma.user.create({
    data: {
      email: "patient@pharmago.cm",
      passwordHash: hashedPassword,
      fullName: "Paul Biya",
      phone: "+237699000111",
      role: "PATIENT",
    },
  });

  const pharmAdmin = await prisma.user.create({
    data: {
      email: "admin@pharmacie-centre.cm",
      passwordHash: hashedPassword,
      fullName: "Dr. Marie Eto'o",
      phone: "+237677111222",
      role: "PHARMACY_ADMIN",
    },
  });

  const cashier = await prisma.user.create({
    data: {
      email: "cashier@pharmacie-centre.cm",
      passwordHash: hashedPassword,
      fullName: "Samuel Nkono",
      phone: "+237699333444",
      role: "CASHIER",
    },
  });

  const agent = await prisma.user.create({
    data: {
      email: "driver@pharmago.cm",
      passwordHash: hashedPassword,
      fullName: "Eric Mben",
      phone: "+237655888999",
      role: "DELIVERY_AGENT",
    },
  });

  const superAdmin = await prisma.user.create({
    data: {
      email: "superadmin@pharmago.cm",
      passwordHash: hashedPassword,
      fullName: "PharmaGo Super Admin",
      phone: "+237690000000",
      role: "PLATFORM_ADMIN",
    },
  });

  console.log("✅ Created 5 initial users with default password 'password123'");

  // 2. Create Pharmacies
  const pharmCentre = await prisma.pharmacy.create({
    data: {
      name: "Pharmacie du Centre",
      slug: "pharmacie-du-centre-akwa",
      address: "Boulevard de la Liberté, Akwa",
      city: "Douala",
      quarter: "Akwa",
      latitude: 4.0511,
      longitude: 9.7085,
      phone: "+237233421100",
      email: "contact@pharmacie-centre.cm",
      licenseNo: "CAM-PH-2023-089",
      isApproved: true,
      isGuard247: true,
      rating: 4.8,
      openingHours: "24h/24",
    },
  });

  const pharmCote = await prisma.pharmacy.create({
    data: {
      name: "Pharmacie de la Côte",
      slug: "pharmacie-de-la-cote-bonanjo",
      address: "Avenue de Général de Gaulle, Bonanjo",
      city: "Douala",
      quarter: "Bonanjo",
      latitude: 4.0435,
      longitude: 9.6872,
      phone: "+237233425511",
      email: "info@pharmacie-cote.cm",
      licenseNo: "CAM-PH-2022-045",
      isApproved: true,
      isGuard247: false,
      rating: 4.6,
      openingHours: "07:30 - 21:00",
    },
  });

  const pharmBastos = await prisma.pharmacy.create({
    data: {
      name: "Pharmacie de Bastos",
      slug: "pharmacie-de-bastos-yaounde",
      address: "Rue 1.820, Bastos",
      city: "Yaoundé",
      quarter: "Bastos",
      latitude: 3.8833,
      longitude: 11.5167,
      phone: "+237222201999",
      email: "bastos@pharmacies.cm",
      licenseNo: "CAM-PH-2021-112",
      isApproved: true,
      isGuard247: true,
      rating: 4.9,
      openingHours: "24h/24",
    },
  });

  console.log("✅ Created 3 pharmacies");

  // 3. Assign Staff to Pharmacies
  await prisma.pharmacyStaff.createMany({
    data: [
      { pharmacyId: pharmCentre.id, userId: pharmAdmin.id, role: "PHARMACY_ADMIN" },
      { pharmacyId: pharmCentre.id, userId: cashier.id, role: "CASHIER" },
    ],
  });

  // 4. Create Products
  const p1 = await prisma.product.create({
    data: {
      pharmacyId: pharmCentre.id,
      name: "Paracétamol Biogaran 500mg",
      category: "Antalgiques & Anti-pyrétiques",
      dosage: "500mg - Boîte de 16 comprimés",
      description: "Soulage la douleur et la fièvre.",
      price: 1200,
      stockQuantity: 150,
      requiresPrescription: false,
      batchNumber: "LOT-2025-A9",
    },
  });

  const p2 = await prisma.product.create({
    data: {
      pharmacyId: pharmCentre.id,
      name: "Coartem 80/480mg (Artemether + Lumefantrine)",
      category: "Anti-paludéens",
      dosage: "Boîte de 6 comprimés",
      description: "Traitement du paludisme simple.",
      price: 3500,
      stockQuantity: 45,
      requiresPrescription: true,
      batchNumber: "LOT-2025-C12",
    },
  });

  const p3 = await prisma.product.create({
    data: {
      pharmacyId: pharmCentre.id,
      name: "Amoxicilline Sandoz 500mg",
      category: "Antibiotiques",
      dosage: "500mg - Boîte de 12 gélules",
      description: "Antibiotique à large spectre.",
      price: 2800,
      stockQuantity: 80,
      requiresPrescription: true,
      batchNumber: "LOT-2024-X4",
    },
  });

  const p4 = await prisma.product.create({
    data: {
      pharmacyId: pharmCentre.id,
      name: "Vitamine C Effervescente 1000mg",
      category: "Vitamines & Compléments",
      dosage: "Tube de 20 comprimés",
      description: "Forme et vitalité.",
      price: 1800,
      stockQuantity: 200,
      requiresPrescription: false,
    },
  });

  console.log("✅ Created sample inventory products");

  // 5. Create Sample Order
  const order = await prisma.order.create({
    data: {
      orderNumber: "PG-2026-0089",
      patientId: patient.id,
      pharmacyId: pharmCentre.id,
      deliveryAgentId: agent.id,
      status: "IN_TRANSIT",
      totalAmount: 4700,
      deliveryAddress: "Bonapriso, Rue des Palmiers, Douala",
      deliveryLat: 4.0322,
      deliveryLng: 9.6954,
      paymentMethod: "MOMO",
      paymentStatus: "PAID",
      items: {
        create: [
          { productId: p1.id, productName: p1.name, unitPrice: 1200, quantity: 1, subtotal: 1200 },
          { productId: p2.id, productName: p2.name, unitPrice: 3500, quantity: 1, subtotal: 3500 },
        ],
      },
    },
  });

  console.log(`✅ Created test order ${order.orderNumber}`);
  console.log("🎉 Seeding completed successfully!");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
