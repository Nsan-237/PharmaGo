import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/splash/welcome_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/register_screen.dart';
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

final appRouter = GoRouter(
  initialLocation: '/splash',
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
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '677 34 21 09';
        return OtpScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
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
      path: '/pharmacy-details',
      builder: (context, state) => const PharmacyDetailsScreen(),
    ),
    GoRoute(
      path: '/request-order',
      builder: (context, state) => const RequestOrderScreen(),
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
  ],
);
