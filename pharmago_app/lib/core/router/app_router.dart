import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/splash/welcome_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/home/bottom_nav_shell.dart';
import '../../features/pharmacy/search_results_screen.dart';
import '../../features/pharmacy/pharmacy_details_screen.dart';
import '../../features/orders/request_order_screen.dart';
import '../../features/orders/order_pending_confirmation_screen.dart';
import '../../features/orders/order_confirmed_screen.dart';
import '../../features/orders/track_order_screen.dart';
import '../../features/payment/payment_screen.dart';
import '../../features/symptoms/symptom_checker_screen.dart';
import '../../features/health_tips/health_tips_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/personal_info_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../features/profile/help_support_screen.dart';
import '../../features/delivery_agent/delivery_agent_screen.dart';
import '../../features/medicines/medicines_catalog_screen.dart';
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RouterNotifier — bridges Riverpod auth state → GoRouter refresh
// ─────────────────────────────────────────────────────────────────────────────
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isAuthenticated = false;
  String _role = '';

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.role != next.role) {
        _isAuthenticated = next.isAuthenticated;
        _role = next.role;
        notifyListeners();
      }
    });
    _isAuthenticated = _ref.read(authProvider).isAuthenticated;
    _role = _ref.read(authProvider).role;
  }

  bool get isAuthenticated => _isAuthenticated;
  String get role => _role;
}

// Protected routes that require login
const _protectedRoutes = [
  '/home',
  '/profile',
  '/orders',
  '/pharmacy-details',
  '/request-order',
  '/payment',
  '/order-pending-confirmation',
  '/order-confirmed',
  '/track-order',
  '/delivery-dashboard',
];

// ─────────────────────────────────────────────────────────────────────────────
// Router Provider — single stable GoRouter instance with refreshListenable
// ─────────────────────────────────────────────────────────────────────────────
final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = notifier.isAuthenticated;
      final role = notifier.role;
      final location = state.matchedLocation;

      // Block protected routes when not logged in
      final needsAuth = _protectedRoutes.any((r) => location.startsWith(r));
      if (needsAuth && !isAuth) return '/login';

      if (isAuth) {
        // Delivery Agent → always goes to /delivery-dashboard
        if (role == 'DELIVERY_AGENT') {
          if (location == '/login' || location == '/register' || location == '/home') {
            return '/delivery-dashboard';
          }
        } else {
          // All other roles → go to /home after login
          if (location == '/login' || location == '/register') {
            return '/home';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            contact: extra?['contact'] as String? ?? '',
            isEmail: extra?['isEmail'] as bool? ?? true,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const BottomNavShell(),
      ),
      GoRoute(
        path: '/search-results',
        builder: (context, state) => const SearchResultsScreen(),
      ),
      GoRoute(
        path: '/medicines',
        builder: (context, state) => const MedicinesCatalogScreen(),
      ),
      GoRoute(
        path: '/pharmacy-details',
        builder: (context, state) => const PharmacyDetailsScreen(),
      ),
      GoRoute(
        path: '/request-order',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RequestOrderScreen(
            initialDrugName: extra?['name'] as String?,
            initialPrice: extra?['price'] as int?,
            initialDosage: extra?['dosage'] as String?,
            initialImageUrl: extra?['imageUrl'] as String?,
            requiresPrescription: extra?['requiresPrescription'] as bool?,
          );
        },
      ),
      GoRoute(
        path: '/order-pending-confirmation',
        builder: (context, state) => const OrderPendingConfirmationScreen(),
      ),
      GoRoute(
        path: '/order-confirmed',
        builder: (context, state) => const OrderConfirmedScreen(),
      ),
      GoRoute(
        path: '/track-order',
        builder: (context, state) => const TrackOrderScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/symptom-checker',
        builder: (context, state) => const SymptomCheckerScreen(),
      ),
      GoRoute(
        path: '/health-tips',
        builder: (context, state) => const HealthTipsScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/personal-info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/profile/help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/delivery-dashboard',
        builder: (context, state) => const DeliveryAgentScreen(),
      ),
    ],
  );
});

// Keep this for any legacy references
final routerProvider = appRouterProvider;
