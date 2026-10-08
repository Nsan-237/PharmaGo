// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo API Constants
// Central configuration for Backend API base URL
// ─────────────────────────────────────────────────────────────────────────────

class ApiConstants {
  /// Live Production API hosted on Railway
  static const String productionApiUrl = 'https://pharmago-production-781f.up.railway.app/api';

  /// Returns the active API base URL.
  /// Can be overridden at build/run time via:
  ///   flutter run --dart-define=API_BASE_URL=http://localhost:5000/api
  static String get baseUrl {
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: productionApiUrl,
    );
  }
}
