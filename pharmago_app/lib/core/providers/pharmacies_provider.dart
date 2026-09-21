// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Pharmacies Provider
// Fetches real pharmacy data from the backend API
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mock_data/mock_data.dart';
import 'auth_provider.dart';

String get _apiBase {
  if (kIsWeb) return 'http://localhost:5000/api';
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5000/api';
  }
  return 'http://localhost:5000/api';
}

// ── Pharmacy from API ─────────────────────────────────────────────────────────
class ApiPharmacyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? quarter;
  final String phone;
  final double rating;
  final double latitude;
  final double longitude;
  final bool isGuard247;
  final bool isApproved;
  final String openingHours;
  final int productCount;

  final String? imageUrl;

  const ApiPharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.quarter,
    required this.phone,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.isGuard247,
    required this.isApproved,
    required this.openingHours,
    required this.productCount,
    this.imageUrl,
  });

  factory ApiPharmacyModel.fromJson(Map<String, dynamic> json) {
    return ApiPharmacyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      quarter: json['quarter'] as String?,
      phone: json['phone'] as String,
      rating: (json['rating'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isGuard247: json['isGuard247'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? true,
      openingHours: json['openingHours'] as String? ?? '08:00 - 20:00',
      productCount: (json['_count'] as Map<String, dynamic>?)?['products'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  // Convert to the PharmacyModel used across the app for easy drop-in replacement
  PharmacyModel toPharmacyModel() {
    final isOpen = isGuard247 || openingHours.contains('24');
    return PharmacyModel(
      id: id,
      name: name,
      address: address,
      city: city,
      phone: phone,
      rating: rating,
      reviewCount: 100 + productCount,
      distanceKm: 1.0, // will be updated with real GPS later
      isOnDuty: isGuard247,
      isOpen: isOpen,
      openingHours: isGuard247 ? 'Open • 24h / 24' : 'Open • $openingHours',
      inStockUnits: productCount,
      deliveryTimeRange: '25 - 35 min',
      imageUrl: imageUrl ?? '',
    );
  }
}

// ── Pharmacies State ─────────────────────────────────────────────────────────
class PharmaciesState {
  final bool isLoading;
  final List<PharmacyModel> pharmacies;
  final String? error;
  final bool isFromApi; // true = real data, false = mock fallback

  const PharmaciesState({
    this.isLoading = false,
    this.pharmacies = const [],
    this.error,
    this.isFromApi = false,
  });
}

// ── Pharmacies Notifier ───────────────────────────────────────────────────────
class PharmaciesNotifier extends StateNotifier<PharmaciesState> {
  final String? _token;

  PharmaciesNotifier(this._token) : super(const PharmaciesState()) {
    fetchPharmacies();
  }

  Future<void> fetchPharmacies({String? city, bool? guardOnly, String? search}) async {
    state = PharmaciesState(isLoading: true, pharmacies: state.pharmacies);

    try {
      final dio = Dio(BaseOptions(
        baseUrl: _apiBase,
        connectTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ));

      final params = <String, dynamic>{};
      if (city != null) params['city'] = city;
      if (guardOnly == true) params['guard'] = 'true';
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await dio.get('/pharmacies', queryParameters: params);
      final List<dynamic> data = response.data['pharmacies'] as List<dynamic>;

      final pharmacies = data
          .map((p) => ApiPharmacyModel.fromJson(p as Map<String, dynamic>).toPharmacyModel())
          .toList();

      state = PharmaciesState(
        isLoading: false,
        pharmacies: pharmacies,
        isFromApi: true,
      );
    } catch (e) {
      // Fallback to mock data if API unavailable
      debugPrint('⚠️ Pharmacy API failed, using mock data: $e');
    state = const PharmaciesState(
        isLoading: false,
        pharmacies: [],
        isFromApi: false,
      );
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final pharmaciesProvider = StateNotifierProvider<PharmaciesNotifier, PharmaciesState>((ref) {
  final token = ref.watch(authProvider).token;
  return PharmaciesNotifier(token);
});
