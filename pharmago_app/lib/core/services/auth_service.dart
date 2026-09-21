// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Auth Service
// Handles login, register, logout with real backend API
// Stores JWT token in SharedPreferences for session persistence
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use correct base URL depending on platform
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    // Windows desktop, macOS, Linux, Web → localhost
    return 'http://localhost:5000/api';
  }

  static const String _tokenKey = 'pharmago_token';
  static const String _userKey = 'pharmago_user';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  // ── Register ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/register',
        data: {
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      // Save token & user to local storage
      final token = response.data['token'] as String;
      final user = Map<String, dynamic>.from(response.data['user'] as Map);
      await _saveSession(token, user);

      return {'success': true, 'user': user, 'token': token};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Registration failed. Check your connection.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final token = response.data['token'] as String;
      final user = Map<String, dynamic>.from(response.data['user'] as Map);
      await _saveSession(token, user);

      return {'success': true, 'user': user, 'token': token};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Login failed. Check your credentials.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _dio.post(
          '$baseUrl/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _clearSession();
    }
  }

  // ── Session Storage (SharedPreferences) ───────────────────────────────────
  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, _encodeUser(user));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    return _decodeUser(userStr);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    try {
      final token = await getToken();
      final currentUser = await getCurrentUser() ?? {};

      // If authenticated with a valid token, attempt backend update
      if (token != null && token.isNotEmpty) {
        try {
          final response = await _dio.put(
            '$baseUrl/auth/profile',
            data: {
              'fullName': fullName.trim(),
              if (phone != null) 'phone': phone.trim(),
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final updatedUser = Map<String, dynamic>.from(response.data['user'] as Map);
          await _saveSession(token, updatedUser);
          return {'success': true, 'user': updatedUser};
        } on DioException catch (dioErr) {
          // If server returned a business validation error (e.g. 400), return it
          if (dioErr.response?.statusCode == 400) {
            return {
              'success': false,
              'error': dioErr.response?.data['error'] ?? 'Données invalides',
            };
          }
          // If server unreachable / offline, update local user
          final localUser = {
            ...currentUser,
            'fullName': fullName.trim(),
            if (phone != null) 'phone': phone.trim(),
          };
          await _saveSession(token, localUser);
          return {'success': true, 'user': localUser};
        }
      }

      // Guest / offline mode: persist locally
      final localUser = {
        ...currentUser,
        'fullName': fullName.trim(),
        if (phone != null) 'phone': phone.trim(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, _encodeUser(localUser));
      return {'success': true, 'user': localUser};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ── Refresh User from Backend ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> refreshUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _dio.get(
        '$baseUrl/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final user = Map<String, dynamic>.from(response.data['user'] as Map);
      await _saveSession(token, user);
      return user;
    } catch (_) {
      return null;
    }
  }

  // Robust JSON encode/decode for user map storage
  String _encodeUser(Map<String, dynamic> user) {
    return jsonEncode(user);
  }

  Map<String, dynamic> _decodeUser(String str) {
    try {
      return Map<String, dynamic>.from(jsonDecode(str) as Map);
    } catch (_) {
      // Backward compatibility with legacy || format
      final map = <String, dynamic>{};
      for (final part in str.split('||')) {
        final idx = part.indexOf('=');
        if (idx > 0) {
          map[part.substring(0, idx)] = part.substring(idx + 1);
        }
      }
      return map;
    }
  }
}

// Singleton instance
final authService = AuthService();
