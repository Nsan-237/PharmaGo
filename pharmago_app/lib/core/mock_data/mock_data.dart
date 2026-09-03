// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Mock Data Layer
//
// ARCHITECTURAL SPECIFICATION & ORDER LIFECYCLE:
// 1. Order requested by client -> initial status: 'en_attente' (Pending Pharmacist Confirmation)
// 2. Pharmacist/Cashier inside `pharmago_web` manually checks actual physical shelf stock
//    and confirms ('confirmee' / 'confirme') or rejects ('rejetee' / 'rejete').
// 3. Client app NEVER has authority to self-confirm stock availability.
// 4. Once confirmed by pharmacy staff, order moves to 'en_route' (Out for Delivery) -> 'livree'.
//
// NOTE: Both apps currently run on local mock state without live backend synchronization.
// In production, real-time WebSockets / SSE / Push Notifications will synchronize
// the cashier confirmation action on the web dashboard to the client mobile app.
// ─────────────────────────────────────────────────────────────────────────────

class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final bool isOnDuty;
  final bool isOpen;
  final String openingHours;
  final int inStockUnits;
  final String deliveryTimeRange;
  final String website;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.rating,
    this.reviewCount = 128,
    required this.distanceKm,
    required this.isOnDuty,
    required this.isOpen,
    required this.openingHours,
    this.inStockUnits = 12,
    this.deliveryTimeRange = '25 - 35 min',
    this.website = 'www.pharmacieducentre.cm',
  });
}

class DrugModel {
  final String id;
  final String name;
  final String category;
  final int price;
  final bool requiresRx;
  final bool inStock;
  final int stockCount;
  final String dosage;

  const DrugModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.requiresRx,
    required this.inStock,
    this.stockCount = 12,
    required this.dosage,
  });
}

class ClientOrderModel {
  final String id;
  final String pharmacyName;
  final String address;
  final List<String> drugs;
  final int total;
  // Order Status Lifecycle:
  // - 'en_attente': Waiting for Pharmacist manual stock confirmation
  // - 'confirme' / 'confirmee': Confirmed available by pharmacist
  // - 'rejetee' / 'rejete': Rejected / unavailable at pharmacy
  // - 'in_progress' / 'en_route': Out for delivery
  // - 'completed' / 'livree': Delivered to client
  // - 'cancelled': Cancelled
  final String status;
  final String createdAt;
  final String estimatedTime;
  final bool isDelivery;
  final String? deliveryAgent;
  final String? deliveryAgentPhone;

  const ClientOrderModel({
    required this.id,
    required this.pharmacyName,
    required this.address,
    required this.drugs,
    required this.total,
    required this.status,
    required this.createdAt,
    this.estimatedTime = '25 - 35 min',
    required this.isDelivery,
    this.deliveryAgent = 'Martin T.',
    this.deliveryAgentPhone = '+237 6 98 76 54 32',
  });
}

class HealthTipModel {
  final String id;
  final String title;
  final String category; // Nutrition, Wellness, Prevention
  final String readTime;
  final String summary;
  final String author;
  final int iconCode;
  final String imageUrl;

  const HealthTipModel({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.summary,
    required this.author,
    required this.iconCode,
    required this.imageUrl,
  });
}

class SymptomChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestions;

  const SymptomChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Data Collections
// ─────────────────────────────────────────────────────────────────────────────

const mockPharmacies = [
  PharmacyModel(
    id: 'ph-1',
    name: 'Pharmacie du Centre',
    address: 'Rue de la Réunification, Bonanjo',
    city: 'Yaoundé',
    phone: '+237 233 42 15 80',
    rating: 4.8,
    reviewCount: 128,
    distanceKm: 0.3,
    isOnDuty: true,
    isOpen: true,
    openingHours: 'Open • Closes at 7:00 PM',
    inStockUnits: 12,
    deliveryTimeRange: '25 - 35 min',
  ),
  PharmacyModel(
    id: 'ph-2',
    name: 'Pharmacie Johnson',
    address: 'Boulevard de la Liberté, Akwa',
    city: 'Yaoundé',
    phone: '+237 233 43 22 10',
    rating: 4.6,
    reviewCount: 94,
    distanceKm: 0.6,
    isOnDuty: false,
    isOpen: true,
    openingHours: 'Open • Closes at 8:00 PM',
    inStockUnits: 8,
    deliveryTimeRange: '30 - 40 min',
  ),
  PharmacyModel(
    id: 'ph-3',
    name: 'Pharmacie Sainte Claire',
    address: 'Carrefour Bastos',
    city: 'Yaoundé',
    phone: '+237 233 41 77 20',
    rating: 4.7,
    reviewCount: 156,
    distanceKm: 1.2,
    isOnDuty: true,
    isOpen: true,
    openingHours: 'Open • 24h / 24',
    inStockUnits: 5,
    deliveryTimeRange: '40 - 55 min',
  ),
  PharmacyModel(
    id: 'ph-4',
    name: 'Pharmacie Centrale',
    address: 'Avenue Kennedy, Centre-Ville',
    city: 'Yaoundé',
    phone: '+237 222 23 11 60',
    rating: 4.5,
    reviewCount: 82,
    distanceKm: 0.3,
    isOnDuty: true,
    isOpen: true,
    openingHours: '9:00 AM - 7:00 PM',
    inStockUnits: 15,
    deliveryTimeRange: '20 - 30 min',
  ),
];

const mockPopularDrugs = [
  DrugModel(
    id: 'd-1',
    name: 'Amoxicillin 500mg',
    category: 'Antibiotique',
    price: 1200,
    requiresRx: true,
    inStock: true,
    stockCount: 12,
    dosage: '500mg • 12 gélules',
  ),
  DrugModel(
    id: 'd-2',
    name: 'Paracetamol 500mg',
    category: 'Analgésique',
    price: 500,
    requiresRx: false,
    inStock: true,
    stockCount: 40,
    dosage: '500mg • Boîte de 16',
  ),
  DrugModel(
    id: 'd-3',
    name: 'Vitamin C 1000mg',
    category: 'Vitamines',
    price: 1200,
    requiresRx: false,
    inStock: true,
    stockCount: 25,
    dosage: '1000mg • Effervescent',
  ),
  DrugModel(
    id: 'd-4',
    name: 'Cough Syrup',
    category: 'Sirop Respiratoire',
    price: 1800,
    requiresRx: false,
    inStock: true,
    stockCount: 10,
    dosage: 'Flacon 150ml',
  ),
];

const mockClientOrders = [
  ClientOrderModel(
    id: '#PGO-4587',
    pharmacyName: 'Pharmacie du Centre',
    address: 'Bastos, Yaoundé',
    drugs: ['Amoxicillin 500mg (x1)'],
    total: 2200,
    status: 'in_progress',
    createdAt: 'Today, 10:24 AM',
    estimatedTime: '25 - 35 min',
    isDelivery: true,
  ),
  ClientOrderModel(
    id: '#PGO-4455',
    pharmacyName: 'Pharmacie Johnson',
    address: 'Omnisports, Yaoundé',
    drugs: ['Paracetamol 500mg (x2)'],
    total: 1000,
    status: 'completed',
    createdAt: '2 days ago',
    estimatedTime: 'Delivered',
    isDelivery: true,
  ),
  ClientOrderModel(
    id: '#PGO-4512',
    pharmacyName: 'Pharmacie Centrale',
    address: 'Bastos, Yaoundé',
    drugs: ['Vitamin C 1000mg (x1)'],
    total: 1200,
    status: 'completed',
    createdAt: '1 week ago',
    estimatedTime: 'Delivered',
    isDelivery: true,
  ),
  ClientOrderModel(
    id: '#PGO-4120',
    pharmacyName: 'Pharmacie Sainte Claire',
    address: 'Mvan, Yaoundé',
    drugs: ['Cough Syrup (x1)'],
    total: 1800,
    status: 'cancelled',
    createdAt: '1 month ago',
    estimatedTime: 'Cancelled',
    isDelivery: true,
  ),
];

const mockHealthTips = [
  HealthTipModel(
    id: 'ht-1',
    title: '5 Tips to Boost Your Immunity',
    category: 'Nutrition',
    readTime: '3 min read',
    summary: 'Discover essential vitamins and habits to strengthen your immune defense during seasonal shifts.',
    author: 'Dr. Jeanette M.',
    iconCode: 0xe51f, // restaurant
    imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&auto=format&fit=crop&q=80',
  ),
  HealthTipModel(
    id: 'ht-2',
    title: 'How to Stay Hydrated Every Day',
    category: 'Wellness',
    readTime: '2 min read',
    summary: 'Simple practical ways to track your daily fluid intake and prevent mild dehydration.',
    author: 'Dr. Alain T.',
    iconCode: 0xe6e8, // water_drop
    imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=600&auto=format&fit=crop&q=80',
  ),
  HealthTipModel(
    id: 'ht-3',
    title: 'The Importance of Regular Exercise',
    category: 'Prevention',
    readTime: '4 min read',
    summary: 'How 20 minutes of daily physical activity reduces cardiovascular risk and boosts vitality.',
    author: 'Dr. Sandrine B.',
    iconCode: 0xe28d, // directions_run
    imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&auto=format&fit=crop&q=80',
  ),
];
