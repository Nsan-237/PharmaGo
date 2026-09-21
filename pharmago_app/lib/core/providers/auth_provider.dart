// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Auth Provider
// Manages authentication state globally using Riverpod
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Represents the current authenticated user
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final String? token;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error,
    );
  }

  String get fullName => user?['fullName'] ?? 'User';
  String get email => user?['email'] ?? '';
  String get phone => user?['phone'] ?? '';
  String get role => user?['role'] ?? 'PATIENT';
  String get userId => user?['id'] ?? '';

  String get firstName {
    final name = fullName.trim();
    if (name.isEmpty || name == 'User') return '';
    return name.split(' ').first;
  }

  String get initials {
    final name = fullName.trim();
    if (name.isEmpty || name == 'User') return 'U';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkExistingSession();
  }

  // Check for saved token on app start
  Future<void> _checkExistingSession() async {
    state = state.copyWith(isLoading: true);
    final isLoggedIn = await authService.isLoggedIn();
    if (isLoggedIn) {
      final user = await authService.getCurrentUser();
      final token = await authService.getToken();
      state = AuthState(
        isAuthenticated: true,
        user: user,
        token: token,
      );
    } else {
      state = const AuthState(isAuthenticated: false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await authService.login(email: email, password: password);

    if (result['success'] == true) {
      state = AuthState(
        isAuthenticated: true,
        user: result['user'],
        token: result['token'],
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'],
      );
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await authService.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    if (result['success'] == true) {
      // Immediately authenticate user upon successful registration
      state = AuthState(
        isAuthenticated: true,
        user: result['user'],
        token: result['token'],
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'],
      );
      return false;
    }
  }

  // Update Profile
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await authService.updateProfile(fullName: fullName, phone: phone);
    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        user: result['user'],
      );
      return {'success': true};
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'],
      );
      return {'success': false, 'error': result['error']};
    }
  }

  // Refresh Profile from server
  Future<void> refreshProfile() async {
    final user = await authService.refreshUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  // Logout
  Future<void> logout() async {
    await authService.logout();
    state = const AuthState(isAuthenticated: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
