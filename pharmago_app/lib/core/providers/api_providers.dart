import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.token,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.login(email, password);
      if (response.statusCode == 200) {
        final data = response.data;
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: data['token'],
          user: data['user'],
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to authenticate: ${e.toString()}',
      );
    }
    return false;
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
