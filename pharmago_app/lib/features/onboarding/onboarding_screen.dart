import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    final slides = [
      _OnboardingData(
        icon: Icons.location_on_rounded,
        iconBg: AppColors.primaryLight,
        iconColor: AppColors.primary,
        titleKey: 'onboarding.findTitle',
        descKey: 'onboarding.findDesc',
      ),
      _OnboardingData(
        icon: Icons.shopping_bag_rounded,
        iconBg: AppColors.accentLight,
        iconColor: AppColors.accent,
        titleKey: 'onboarding.orderTitle',
        descKey: 'onboarding.orderDesc',
      ),
      _OnboardingData(
        icon: Icons.electric_moped_rounded,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: AppColors.success,
        titleKey: 'onboarding.deliverTitle',
        descKey: 'onboarding.deliverDesc',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language Switcher Chip
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              avatar: Text(isFr ? '🇫🇷' : '🇬🇧', style: const TextStyle(fontSize: 14)),
              label: Text(
                isFr ? 'FR' : 'EN',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              backgroundColor: AppColors.background,
              side: const BorderSide(color: AppColors.border),
              onPressed: () {
                ref.read(localeProvider.notifier).toggleLanguage();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Slide content PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Hero Card Graphic
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: slide.iconBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: slide.iconColor.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              slide.icon,
                              size: 64,
                              color: slide.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Title
                        Text(
                          context.tr(slide.titleKey, ref: ref),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sora(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          context.tr(slide.descKey, ref: ref),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textBody,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator dots + Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      if (_currentPage < slides.length - 1) ...[
                        TextButton(
                          onPressed: () => context.go('/welcome'),
                          child: Text(
                            context.tr('onboarding.skip', ref: ref),
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(context.tr('onboarding.next', ref: ref)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.go('/welcome'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('onboarding.start', ref: ref),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String titleKey;
  final String descKey;

  _OnboardingData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.titleKey,
    required this.descKey,
  });
}
