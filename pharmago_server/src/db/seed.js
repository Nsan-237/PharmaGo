// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Database Seed Script
// Seeds the Supabase PostgreSQL database with:
// - 1 Platform Admin + 10 Pharmacy Staff users
// - 10 Pharmacies (5 Yaoundé + 5 Douala) matching mock data
// - 6 Products per pharmacy (60 total)
// - Audit Log table setup
// ─────────────────────────────────────────────────────────────────────────────

import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Starting PharmaGo Database Seed...\n");

  // ── 1. Create Platform Admin ──────────────────────────────────────────────
  console.log("👤 Creating Platform Admin...");
  const adminHash = await bcrypt.hash("PharmaAdmin@2026", 10);
  const platformAdmin = await prisma.user.upsert({
    where: { email: "admin@pharmago.cm" },
    update: {},
    create: {
      email: "admin@pharmago.cm",
      passwordHash: adminHash,
      fullName: "Super Admin PharmaGo",
      phone: "+237699000001",
      role: "PLATFORM_ADMIN",
      isApproved: true,
    },
  });
  console.log("  ✅ Platform Admin created:", platformAdmin.email);

  // ── 2. Create Demo Patient ────────────────────────────────────────────────
  console.log("👤 Creating Demo Patient...");
  const patientHash = await bcrypt.hash("Patient@2026", 10);
  const demoPatient = await prisma.user.upsert({
    where: { email: "patient@pharmago.cm" },
    update: {},
    create: {
      email: "patient@pharmago.cm",
      passwordHash: patientHash,
      fullName: "Jean-Paul Mbarga",
      phone: "+237677342109",
      role: "PATIENT",
      isApproved: true,
    },
  });
  console.log("  ✅ Demo Patient created:", demoPatient.email);

  // ── 3. Create Pharmacies ──────────────────────────────────────────────────
  console.log("\n🏥 Creating Pharmacies...");

  const pharmacyData = [
    // Yaoundé Pharmacies
    {
      name: "Pharmacie Don Bosco",
      slug: "pharmacie-don-bosco",
      address: "Carrefour Don Bosco, Mimboman",
      city: "Yaoundé",
      quarter: "Mimboman",
      latitude: 3.8784,
      longitude: 11.5265,
      phone: "+237222214560",
      email: "donbosco@pharmago.cm",
      isApproved: true,
      isGuard247: true,
      rating: 4.8,
      openingHours: "24h / 24",
      adminEmail: "admin.donbosco@pharmago.cm",
      adminName: "Dr. Paul Nkoa",
    },
    {
      name: "Pharmacie Sainte Claire",
      slug: "pharmacie-sainte-claire",
      address: "Carrefour Bastos",
      city: "Yaoundé",
      quarter: "Bastos",
      latitude: 3.8796,
      longitude: 11.5148,
      phone: "+237222207720",
      email: "sainteclaire@pharmago.cm",
      isApproved: true,
      isGuard247: true,
      rating: 4.7,
      openingHours: "24h / 24",
      adminEmail: "admin.sainteclaire@pharmago.cm",
      adminName: "Dr. Marie Tchouala",
    },
    {
      name: "Pharmacie Centrale",
      slug: "pharmacie-centrale-yaounde",
      address: "Avenue Kennedy, Centre-Ville",
      city: "Yaoundé",
      quarter: "Centre-Ville",
      latitude: 3.8667,
      longitude: 11.5167,
      phone: "+237222231160",
      email: "centrale@pharmago.cm",
      isApproved: true,
      isGuard247: false,
      rating: 4.6,
      openingHours: "08:00 - 20:00",
      adminEmail: "admin.centrale.yde@pharmago.cm",
      adminName: "Dr. Robert Ndi",
    },
    {
      name: "Pharmacie d'Omnisports",
      slug: "pharmacie-omnisports",
      address: "Face Stade Omnisports Ahmadou Ahidjo",
      city: "Yaoundé",
      quarter: "Omnisports",
      latitude: 3.8720,
      longitude: 11.5225,
      phone: "+237222218840",
      email: "omnisports@pharmago.cm",
      isApproved: true,
      isGuard247: false,
      rating: 4.5,
      openingHours: "08:00 - 21:00",
      adminEmail: "admin.omnisports@pharmago.cm",
      adminName: "Dr. Sylvie Abessolo",
    },
    {
      name: "Pharmacie du Mfoundi",
      slug: "pharmacie-du-mfoundi",
      address: "Montée Elig-Essono, Mfoundi",
      city: "Yaoundé",
      quarter: "Mfoundi",
      latitude: 3.8810,
      longitude: 11.5185,
      phone: "+237222223412",
      email: "mfoundi@pharmago.cm",
      isApproved: true,
      isGuard247: true,
      rating: 4.6,
      openingHours: "24h / 24",
      adminEmail: "admin.mfoundi@pharmago.cm",
      adminName: "Dr. Françoise Etonde",
    },
    // Douala Pharmacies
    {
      name: "Pharmacie du Centre",
      slug: "pharmacie-du-centre-douala",
      address: "Rue de la Réunification, Bonanjo",
      city: "Douala",
      quarter: "Bonanjo",
      latitude: 4.0511,
      longitude: 9.7085,
      phone: "+237233421580",
      email: "centre.dla@pharmago.cm",
      isApproved: true,
      isGuard247: false,
      rating: 4.8,
      openingHours: "08:00 - 20:00",
      adminEmail: "admin.centre.dla@pharmago.cm",
      adminName: "Dr. Alain Biya",
    },
    {
      name: "Pharmacie Johnson",
      slug: "pharmacie-johnson",
      address: "Boulevard de la Liberté, Akwa",
      city: "Douala",
      quarter: "Akwa",
      latitude: 4.0558,
      longitude: 9.7042,
      phone: "+237233432210",
      email: "johnson@pharmago.cm",
      isApproved: true,
      isGuard247: true,
      rating: 4.7,
      openingHours: "24h / 24",
      adminEmail: "admin.johnson@pharmago.cm",
      adminName: "Dr. Johnson Epée",
    },
    {
      name: "Pharmacie de la Côte",
      slug: "pharmacie-de-la-cote",
      address: "Boulevard Ahmadou Ahidjo, New Bell",
      city: "Douala",
      quarter: "New Bell",
      latitude: 4.0489,
      longitude: 9.7132,
      phone: "+237233426630",
      email: "lacote@pharmago.cm",
      isApproved: true,
      isGuard247: false,
      rating: 4.5,
      openingHours: "08:00 - 19:30",
      adminEmail: "admin.lacote@pharmago.cm",
      adminName: "Dr. Cécile Manga",
    },
    {
      name: "Pharmacie des Nations",
      slug: "pharmacie-des-nations",
      address: "Carrefour Grand Moulin, Deido",
      city: "Douala",
      quarter: "Deido",
      latitude: 4.0605,
      longitude: 9.7165,
      phone: "+237233419015",
      email: "nations@pharmago.cm",
      isApproved: true,
      isGuard247: false,
      rating: 4.6,
      openingHours: "08:00 - 21:00",
      adminEmail: "admin.nations@pharmago.cm",
      adminName: "Dr. Bernard Essomba",
    },
    {
      name: "Pharmacie Sainte Thérèse",
      slug: "pharmacie-sainte-therese",
      address: "Carrefour Agip, Bepanda",
      city: "Douala",
      quarter: "Bepanda",
      latitude: 4.0632,
      longitude: 9.7201,
      phone: "+237233401822",
      email: "stherese@pharmago.cm",
      isApproved: true,
      isGuard247: true,
      rating: 4.4,
      openingHours: "24h / 24",
      adminEmail: "admin.stherese@pharmago.cm",
      adminName: "Dr. Thérèse Moukouri",
    },
  ];

  const createdPharmacies = [];

  for (const phData of pharmacyData) {
    const { adminEmail, adminName, ...pharmacyFields } = phData;

    // Create pharmacy
    const pharmacy = await prisma.pharmacy.upsert({
      where: { slug: pharmacyFields.slug },
      update: {},
      create: pharmacyFields,
    });

    // Create pharmacy admin user
    const adminPassword = await bcrypt.hash("PharmAdmin@2026", 10);
    const adminUser = await prisma.user.upsert({
      where: { email: adminEmail },
      update: {},
      create: {
        email: adminEmail,
        passwordHash: adminPassword,
        fullName: adminName,
        phone: pharmacyFields.phone,
        role: "PHARMACY_ADMIN",
        isApproved: true,
      },
    });

    // Link admin to pharmacy
    await prisma.pharmacyStaff.upsert({
      where: { pharmacyId_userId: { pharmacyId: pharmacy.id, userId: adminUser.id } },
      update: {},
      create: {
        pharmacyId: pharmacy.id,
        userId: adminUser.id,
        role: "PHARMACY_ADMIN",
      },
    });

    // Create cashier for each pharmacy
    const cashierHash = await bcrypt.hash("Cashier@2026", 10);
    const cashierName = `Cashier ${pharmacy.name.split(" ").pop()}`;
    const cashierEmail = `cashier.${pharmacy.slug}@pharmago.cm`;
    const cashierUser = await prisma.user.upsert({
      where: { email: cashierEmail },
      update: {},
      create: {
        email: cashierEmail,
        passwordHash: cashierHash,
        fullName: cashierName,
        phone: pharmacyFields.phone,
        role: "CASHIER",
        isApproved: true,
      },
    });

    await prisma.pharmacyStaff.upsert({
      where: { pharmacyId_userId: { pharmacyId: pharmacy.id, userId: cashierUser.id } },
      update: {},
      create: {
        pharmacyId: pharmacy.id,
        userId: cashierUser.id,
        role: "CASHIER",
      },
    });

    createdPharmacies.push(pharmacy);
    console.log(`  ✅ Created: ${pharmacy.name} (${pharmacy.city})`);
  }

  // ── 4. Create Products for Each Pharmacy ─────────────────────────────────
  console.log("\n💊 Creating Products (medications)...");

  const products = [
    {
      name: "Amoxicillin 500mg",
      category: "Antibiotique",
      dosage: "500mg • 12 gélules",
      description: "Antibiotique à large spectre pour infections bactériennes",
      price: 1200,
      stockQuantity: 18,
      requiresPrescription: true,
      imageUrl: "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80",
    },
    {
      name: "Paracetamol 500mg",
      category: "Analgésique",
      dosage: "500mg • Boîte de 16",
      description: "Antidouleur et antipyrétique de référence",
      price: 500,
      stockQuantity: 50,
      requiresPrescription: false,
      imageUrl: "https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=400&auto=format&fit=crop&q=80",
    },
    {
      name: "Coartem 20/120",
      category: "Antipaludéen",
      dosage: "24 comprimés • Paludisme",
      description: "Traitement antipaludéen de référence au Cameroun",
      price: 2500,
      stockQuantity: 22,
      requiresPrescription: false,
      imageUrl: "https://images.unsplash.com/photo-1576602976047-174e57a47881?w=400&auto=format&fit=crop&q=80",
    },
    {
      name: "Vitamin C 1000mg",
      category: "Vitamines",
      dosage: "1000mg • 20 Effervescents",
      description: "Supplément vitaminique pour renforcer les défenses immunitaires",
      price: 1500,
      stockQuantity: 30,
      requiresPrescription: false,
      imageUrl: "https://images.unsplash.com/photo-1550572017-edd951aa8f72?w=400&auto=format&fit=crop&q=80",
    },
    {
      name: "Sirop Toplexil",
      category: "Sirop Toux",
      dosage: "Flacon 150ml • Toux sèche",
      description: "Sirop antitussif pour toux sèche et irritante",
      price: 2000,
      stockQuantity: 14,
      requiresPrescription: false,
      imageUrl: "https://images.unsplash.com/photo-1512069772995-ec65ed45afd6?w=400&auto=format&fit=crop&q=80",
    },
    {
      name: "Ibuprofen 400mg",
      category: "Anti-inflammatoire",
      dosage: "400mg • 10 comprimés",
      description: "Anti-inflammatoire non stéroïdien pour douleurs et fièvre",
      price: 800,
      stockQuantity: 35,
      requiresPrescription: false,
      imageUrl: "https://images.unsplash.com/photo-1585435557343-3b092031a831?w=400&auto=format&fit=crop&q=80",
    },
  ];

  for (const pharmacy of createdPharmacies) {
    for (const product of products) {
      // Check if product already exists for this pharmacy
      const existing = await prisma.product.findFirst({
        where: {
          pharmacyId: pharmacy.id,
          name: product.name,
        },
      });

      if (!existing) {
        await prisma.product.create({
          data: {
            ...product,
            pharmacyId: pharmacy.id,
          },
        });
      } else {
        await prisma.product.update({
          where: { id: existing.id },
          data: { stockQuantity: product.stockQuantity },
        });
      }
    }
    console.log(`  ✅ Products added to: ${pharmacy.name}`);
  }

  // ── 5. Create Delivery Agent ──────────────────────────────────────────────
  console.log("\n🛵 Creating Delivery Agent...");
  const agentHash = await bcrypt.hash("Agent@2026", 10);
  await prisma.user.upsert({
    where: { email: "agent@pharmago.cm" },
    update: {},
    create: {
      email: "agent@pharmago.cm",
      passwordHash: agentHash,
      fullName: "Martin Tamba",
      phone: "+237698765432",
      role: "DELIVERY_AGENT",
      isApproved: true,
    },
  });
  console.log("  ✅ Delivery Agent created: agent@pharmago.cm");

  console.log("\n✅ Database Seed Complete!\n");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("📋 Demo Credentials:");
  console.log("   Platform Admin: admin@pharmago.cm       | PharmaAdmin@2026");
  console.log("   Demo Patient:   patient@pharmago.cm     | Patient@2026");
  console.log("   Pharmacy Admin: admin.don-bosco@pharmago.cm | PharmAdmin@2026");
  console.log("   Cashier:        cashier.pharmacie-don-bosco@pharmago.cm | Cashier@2026");
  console.log("   Delivery Agent: agent@pharmago.cm       | Agent@2026");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
}

main()
  .catch((e) => {
    console.error("❌ Seed Error:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
