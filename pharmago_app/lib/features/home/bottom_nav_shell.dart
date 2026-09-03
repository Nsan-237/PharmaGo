import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
