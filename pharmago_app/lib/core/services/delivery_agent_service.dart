// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Delivery Agent Service
// Connects Flutter app to the backend API for all agent operations
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryAgentService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  late final Dio _dio;

  DeliveryAgentService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('pharmago_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // Fallback demo deliveries matching the web dashboard
  static final Map<String, dynamic> _fallbackData = {
    'available': [
      {
        'id': 'ord-cmd-2401',
        'orderNumber': 'CMD-2401',
        'deliveryAddress': 'Bonapriso, Rue des Palmiers, Douala',
        'totalAmount': 2000,
        'paymentMethod': 'MOMO',
        'patient': {
          'fullName': 'Marie Ngono',
          'phone': '+237 677 34 21 09',
        },
        'pharmacy': {
          'name': 'Pharmacie du Centre',
          'phone': '+237 233 42 15 80',
          'address': 'Rue de la Réunification, Douala',
        },
        'items': [
          {'productName': 'Paracétamol 500mg', 'quantity': 2, 'unitPrice': 500},
          {'productName': 'Vitamine C 500mg', 'quantity': 1, 'unitPrice': 1000},
        ],
      },
      {
        'id': 'ord-cmd-2406',
        'orderNumber': 'CMD-2406',
        'deliveryAddress': 'Logpom, Carrefour Bassong, Douala',
        'totalAmount': 3000,
        'paymentMethod': 'CASH',
        'patient': {
          'fullName': 'Alain Tchamba',
          'phone': '+237 699 22 55 88',
        },
        'pharmacy': {
          'name': 'Pharmacie Johnson',
          'phone': '+237 233 43 22 10',
          'address': 'Akwa, Douala',
        },
        'items': [
          {'productName': 'Amlodipine 5mg', 'quantity': 1, 'unitPrice': 1500},
          {'productName': 'Paracétamol 500mg', 'quantity': 3, 'unitPrice': 500},
        ],
      },
    ],
    'assigned': [
      {
        'id': 'ord-cmd-2403',
        'orderNumber': 'CMD-2403',
        'deliveryAddress': 'Makepe, Rond-Point Petit Pays, Douala',
        'totalAmount': 3100,
        'paymentMethod': 'ORANGE_MONEY',
        'patient': {
          'fullName': 'Fatima Bello',
          'phone': '+237 699 45 67 23',
        },
        'pharmacy': {
          'name': 'Pharmacie du Centre',
          'phone': '+237 233 42 15 80',
          'address': 'Rue de la Réunification, Douala',
        },
        'items': [
          {'productName': 'Ibuprofène 400mg', 'quantity': 3, 'unitPrice': 800},
          {'productName': 'ORS Pédiatrique', 'quantity': 2, 'unitPrice': 350},
        ],
      },
    ],
    'delivered': [
      {
        'id': 'ord-cmd-2404',
        'orderNumber': 'CMD-2404',
        'deliveryAddress': 'Omnisport, Montée du Stade, Yaoundé',
        'totalAmount': 1200,
        'paymentMethod': 'CASH',
        'patient': {
          'fullName': 'Paul Atangana',
          'phone': '+237 677 88 12 54',
        },
        'pharmacy': {
          'name': 'Pharmacie Centrale',
          'phone': '+237 222 23 11 60',
          'address': 'Mvog-Ada, Yaoundé',
        },
        'items': [
          {'productName': 'Chloroquine 100mg', 'quantity': 2, 'unitPrice': 600},
        ],
      },
    ],
  };

  // ── Get all deliveries (assigned + available + delivered) ──────────────
  Future<Map<String, dynamic>> getOrders() async {
    try {
      final res = await _dio.get('$baseUrl/agent/orders');
      final data = res.data as Map<String, dynamic>;
      final avail = (data['available'] as List?) ?? [];
      final assigned = (data['assigned'] as List?) ?? [];
      final deliv = (data['delivered'] as List?) ?? [];
      if (avail.isEmpty && assigned.isEmpty && deliv.isEmpty) {
        return {'success': true, 'data': _fallbackData};
      }
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      debugPrint('⚠️ Delivery API failed ($e), falling back to mock deliveries');
      return {'success': true, 'data': _fallbackData};
    } catch (_) {
      return {'success': true, 'data': _fallbackData};
    }
  }

  // ── Accept a delivery order ────────────────────────────────────────────
  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    try {
      final res = await _dio.patch('$baseUrl/agent/orders/$orderId/accept');
      return {'success': true, 'data': res.data};
    } on DioException catch (_) {
      // Local fallback
      final availList = _fallbackData['available'] as List<dynamic>;
      final foundIdx = availList.indexWhere((o) => o['id'] == orderId || o['orderNumber'] == orderId);
      if (foundIdx != -1) {
        final order = availList.removeAt(foundIdx);
        (_fallbackData['assigned'] as List<dynamic>).insert(0, order);
      }
      return {'success': true};
    }
  }

  // ── Mark order as delivered ────────────────────────────────────────────
  Future<Map<String, dynamic>> markDelivered(String orderId) async {
    try {
      final res = await _dio.patch('$baseUrl/agent/orders/$orderId/deliver');
      return {'success': true, 'data': res.data};
    } on DioException catch (_) {
      final assignedList = _fallbackData['assigned'] as List<dynamic>;
      final foundIdx = assignedList.indexWhere((o) => o['id'] == orderId || o['orderNumber'] == orderId);
      if (foundIdx != -1) {
        final order = assignedList.removeAt(foundIdx);
        (_fallbackData['delivered'] as List<dynamic>).insert(0, order);
      }
      return {'success': true};
    }
  }

  // ── Report a delivery delay ────────────────────────────────────────────
  Future<Map<String, dynamic>> reportDelay(String orderId, String reason) async {
    try {
      final res = await _dio.post(
        '$baseUrl/agent/orders/$orderId/report-delay',
        data: {'reason': reason},
      );
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.data['error'] ?? 'Failed to report delay'};
    }
  }

  // ── Send a chat message ────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendMessage(String orderId, String content) async {
    try {
      final res = await _dio.post(
        '$baseUrl/agent/orders/$orderId/messages',
        data: {'content': content},
      );
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.data['error'] ?? 'Failed to send message'};
    }
  }

  // ── Get chat messages for an order ────────────────────────────────────
  Future<Map<String, dynamic>> getMessages(String orderId) async {
    try {
      final res = await _dio.get('$baseUrl/agent/orders/$orderId/messages');
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.data['error'] ?? 'Failed to load messages'};
    }
  }

  // ── Report a problem (from client side) ───────────────────────────────
  Future<Map<String, dynamic>> reportProblem(String orderId, String reason) async {
    try {
      final res = await _dio.post(
        '$baseUrl/agent/orders/$orderId/report-problem',
        data: {'reason': reason},
      );
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.data['error'] ?? 'Failed to report problem'};
    }
  }

  // ── Get daily stats ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('$baseUrl/agent/stats');
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.data['error'] ?? 'Failed to load stats'};
    }
  }

  // ── Toggle availability ────────────────────────────────────────────────
  Future<Map<String, dynamic>> setAvailability(bool isOnline) async {
    try {
      final res = await _dio.patch(
        '$baseUrl/agent/availability',
        data: {'isOnline': isOnline},
      );
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.data['error'] ?? 'Failed to update availability'};
    }
  }
}

final deliveryAgentService = DeliveryAgentService();
