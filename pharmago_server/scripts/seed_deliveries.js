import prisma from "../src/db/prisma.js";

async function seed() {
  console.log("Seeding delivery orders matching web dashboard...");

  const clients = [
    { email: "marie.ngono@pharmago.cm", fullName: "Marie Ngono", phone: "+237 677 34 21 09" },
    { email: "fatima.bello@pharmago.cm", fullName: "Fatima Bello", phone: "+237 699 45 67 23" },
    { email: "alain.tchamba@pharmago.cm", fullName: "Alain Tchamba", phone: "+237 699 22 55 88" },
    { email: "paul.atangana@pharmago.cm", fullName: "Paul Atangana", phone: "+237 677 88 12 54" },
  ];

  const clientMap = {};
  for (const c of clients) {
    let user = await prisma.user.findUnique({ where: { email: c.email } });
    if (!user) {
      user = await prisma.user.create({
        data: {
          email: c.email,
          fullName: c.fullName,
          phone: c.phone,
          passwordHash: "$2b$10$abcdefg1234567890dummyhash",
          role: "PATIENT",
        },
      });
    }
    clientMap[c.email] = user;
  }

  const pharms = await prisma.pharmacy.findMany();
  const centrePharm = pharms.find(p => p.name.includes("Centre")) || pharms[0];
  const johnsonPharm = pharms.find(p => p.name.includes("Johnson")) || pharms[1];
  const centralePharm = pharms.find(p => p.name.includes("Centrale")) || pharms[2];

  // Get products for pharmacies
  const allProducts = await prisma.product.findMany();
  const getProdId = (name, pharmId) => {
    const found = allProducts.find(p => p.name.toLowerCase().includes(name.toLowerCase()) && p.pharmacyId === pharmId)
      || allProducts.find(p => p.name.toLowerCase().includes(name.toLowerCase()))
      || allProducts[0];
    return found.id;
  };

  const drivers = await prisma.user.findMany({ where: { role: "DELIVERY_AGENT" } });
  const driverId = drivers[0]?.id || null;

  const ordersToSeed = [
    {
      orderNumber: "CMD-2401",
      patientId: clientMap["marie.ngono@pharmago.cm"].id,
      pharmacyId: centrePharm.id,
      deliveryAddress: "Bonapriso, Rue des Palmiers, Douala",
      deliveryLat: 4.0250,
      deliveryLng: 9.7020,
      status: "READY_FOR_PICKUP",
      deliveryAgentId: null,
      paymentMethod: "MOMO",
      paymentStatus: "PAID",
      totalAmount: 2000,
      items: [
        {
          productId: getProdId("Paracetamol", centrePharm.id),
          productName: "Paracétamol 500mg",
          quantity: 2,
          unitPrice: 500,
          subtotal: 1000,
        },
        {
          productId: getProdId("Vitamin C", centrePharm.id),
          productName: "Vitamine C 500mg",
          quantity: 1,
          unitPrice: 1000,
          subtotal: 1000,
        },
      ],
    },
    {
      orderNumber: "CMD-2406",
      patientId: clientMap["alain.tchamba@pharmago.cm"].id,
      pharmacyId: johnsonPharm ? johnsonPharm.id : centrePharm.id,
      deliveryAddress: "Logpom, Carrefour Bassong, Douala",
      deliveryLat: 4.0720,
      deliveryLng: 9.7430,
      status: "CONFIRMED",
      deliveryAgentId: null,
      paymentMethod: "CASH",
      paymentStatus: "PENDING",
      totalAmount: 3000,
      items: [
        {
          productId: getProdId("Ibuprofen", johnsonPharm.id),
          productName: "Amlodipine 5mg",
          quantity: 1,
          unitPrice: 1500,
          subtotal: 1500,
        },
        {
          productId: getProdId("Paracetamol", johnsonPharm.id),
          productName: "Paracétamol 500mg",
          quantity: 3,
          unitPrice: 500,
          subtotal: 1500,
        },
      ],
    },
    {
      orderNumber: "CMD-2403",
      patientId: clientMap["fatima.bello@pharmago.cm"].id,
      pharmacyId: centrePharm.id,
      deliveryAddress: "Makepe, Rond-Point Petit Pays, Douala",
      deliveryLat: 4.0810,
      deliveryLng: 9.7350,
      status: "IN_TRANSIT",
      deliveryAgentId: driverId,
      paymentMethod: "ORANGE_MONEY",
      paymentStatus: "PAID",
      totalAmount: 3100,
      items: [
        {
          productId: getProdId("Ibuprofen", centrePharm.id),
          productName: "Ibuprofène 400mg",
          quantity: 3,
          unitPrice: 800,
          subtotal: 2400,
        },
        {
          productId: getProdId("Paracetamol", centrePharm.id),
          productName: "ORS Pédiatrique",
          quantity: 2,
          unitPrice: 350,
          subtotal: 700,
        },
      ],
    },
    {
      orderNumber: "CMD-2404",
      patientId: clientMap["paul.atangana@pharmago.cm"].id,
      pharmacyId: centralePharm ? centralePharm.id : centrePharm.id,
      deliveryAddress: "Omnisport, Montée du Stade, Yaoundé",
      deliveryLat: 3.8820,
      deliveryLng: 11.5360,
      status: "DELIVERED",
      deliveryAgentId: driverId,
      paymentMethod: "CASH",
      paymentStatus: "PAID",
      totalAmount: 1200,
      items: [
        {
          productId: getProdId("Amoxicillin", centralePharm.id),
          productName: "Chloroquine 100mg",
          quantity: 2,
          unitPrice: 600,
          subtotal: 1200,
        },
      ],
    },
  ];

  for (const o of ordersToSeed) {
    const existing = await prisma.order.findUnique({ where: { orderNumber: o.orderNumber } });
    if (!existing) {
      await prisma.order.create({
        data: {
          orderNumber: o.orderNumber,
          patientId: o.patientId,
          pharmacyId: o.pharmacyId,
          deliveryAddress: o.deliveryAddress,
          deliveryLat: o.deliveryLat,
          deliveryLng: o.deliveryLng,
          status: o.status,
          deliveryAgentId: o.deliveryAgentId,
          paymentMethod: o.paymentMethod,
          paymentStatus: o.paymentStatus,
          totalAmount: o.totalAmount,
          items: { create: o.items },
        },
      });
      console.log(`✓ Created order ${o.orderNumber} with status ${o.status}`);
    } else {
      console.log(`- Order ${o.orderNumber} already exists`);
    }
  }

  console.log("Seeding complete!");
  process.exit(0);
}

seed().catch(e => {
  console.error("Seed error:", e);
  process.exit(1);
});
