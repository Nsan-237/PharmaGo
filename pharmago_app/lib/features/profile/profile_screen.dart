import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;
    final auth = ref.watch(authProvider);

    final displayName = auth.isAuthenticated
        ? (auth.fullName.isNotEmpty ? auth.fullName : 'Client')
        : (isFr ? 'Client Invité' : 'Guest Client');
    final displayContact = auth.phone.isNotEmpty
        ? auth.phone
        : (auth.email.isNotEmpty ? auth.email : (isFr ? 'Compte PharmaGo' : 'PharmaGo Account'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          context.tr('profile.title', ref: ref),
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // ── 1. User Avatar & Info ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        auth.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayContact,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── 2. Settings Menu List ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: context.tr('profile.personalInfo', ref: ref),
                    onTap: () => context.push('/profile/personal-info'),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _ProfileMenuItem(
                    icon: Icons.location_on_outlined,
                    title: context.tr('profile.addresses', ref: ref),
                    onTap: () => context.push('/profile/addresses'),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _ProfileMenuItem(
                    icon: Icons.payment_rounded,
                    title: context.tr('profile.paymentMethods', ref: ref),
                    onTap: () => context.push('/payment'),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _ProfileMenuItem(
                    icon: Icons.description_outlined,
                    title: context.tr('profile.myPrescriptions', ref: ref),
                    onTap: () => context.push('/request-order'),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  // Settings + Language Switcher
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
                    title: Text(
                      context.tr('profile.language', ref: ref),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    trailing: ActionChip(
                      avatar: Text(isFr ? '🇫🇷' : '🇬🇧', style: const TextStyle(fontSize: 13)),
                      label: Text(
                        isFr ? 'Français' : 'English',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      backgroundColor: AppColors.primaryLight,
                      side: const BorderSide(color: AppColors.primary),
                      onPressed: () {
                        ref.read(localeProvider.notifier).toggleLanguage();
                      },
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _ProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: context.tr('profile.helpSupport', ref: ref),
                    onTap: () => context.push('/profile/help-support'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── 3. Logout Button ──
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.power_settings_new_rounded, color: AppColors.error, size: 20),
                label: Text(
                  context.tr('profile.logout', ref: ref),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
