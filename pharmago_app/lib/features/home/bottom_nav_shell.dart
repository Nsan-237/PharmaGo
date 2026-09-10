import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import 'home_screen.dart';
import '../pharmacy/pharmacy_list_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PharmacyListScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: Container(
        height: 52,
        margin: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          heroTag: 'pharmAiChatbotFab',
          onPressed: () => context.push('/symptom-checker'),
          backgroundColor: AppColors.primary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Colors.white, width: 1.5),
          ),
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PharmAI',
                style: GoogleFonts.sora(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80), // Online green dot
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppColors.primaryLight,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon:
                  const Icon(Icons.home_rounded, color: AppColors.primary),
              label: isFr ? 'Accueil' : 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_pharmacy_outlined),
              selectedIcon: const Icon(Icons.local_pharmacy_rounded,
                  color: AppColors.primary),
              label: isFr ? 'Pharmacies' : 'Pharmacies',
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary),
              label: isFr ? 'Commandes' : 'Orders',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded,
                  color: AppColors.primary),
              label: isFr ? 'Compte' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
