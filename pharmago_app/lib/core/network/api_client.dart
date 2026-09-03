import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator default host PC loopback or localhost
  late final Dio _dio;

  ApiClient({String? authToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ),
    );
  }

  // Auth Endpoints
  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(Map<String, dynamic> userData) async {
    return await _dio.post('/auth/register', data: userData);
  }

  // Pharmacy Endpoints
  Future<Response> getPharmacies({double? lat, double? lng, String? city, String? search, bool? isGuard}) async {
    final queryParams = <String, dynamic>{};
    if (lat != null) queryParams['lat'] = lat;
    if (lng != null) queryParams['lng'] = lng;
    if (city != null) queryParams['city'] = city;
    if (search != null) queryParams['search'] = search;
    if (isGuard != null) queryParams['isGuard'] = isGuard;

    return await _dio.get('/pharmacies', queryParameters: queryParams);
  }

  Future<Response> getPharmacyDetails(String idOrSlug) async {
    return await _dio.get('/pharmacies/$idOrSlug');
  }

  // Product Search
  Future<Response> searchProducts(String query) async {
    return await _dio.get('/products/search', queryParameters: {'q': query});
  }

  // Orders
  Future<Response> createOrder(Map<String, dynamic> orderData) async {
    return await _dio.post('/orders', data: orderData);
  }

  Future<Response> getPatientOrders() async {
    return await _dio.get('/orders');
  }

  // Payment & Mobile Money
  Future<Response> initiatePayment(String orderId, double amount, String phone, String provider) async {
    return await _dio.post('/payments/initiate', data: {
      'orderId': orderId,
      'amount': amount,
      'phone': phone,
      'provider': provider,
    });
  }

  // Driver Realtime GPS Tracking
  Future<Response> updateDriverLocation(String orderId, double lat, double lng) async {
    return await _dio.post('/tracking/location', data: {
      'orderId': orderId,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<Response> getDriverLocation(String orderId) async {
    return await _dio.get('/tracking/location/$orderId');
  }
}
