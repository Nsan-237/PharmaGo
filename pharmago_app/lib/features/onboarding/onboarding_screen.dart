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
                        // Rich Realistic Illustration Graphic Card
                        _buildSlideIllustration(index, slide, isFr),
                        const SizedBox(height: 36),

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

  Widget _buildSlideIllustration(int index, _OnboardingData slide, bool isFr) {
    final String imagePath;
    final String badgeText;
    final IconData badgeIcon;
    final Color badgeColor;

    if (index == 0) {
      imagePath = 'assets/images/onboarding_find_pharmacy.jpg';
      badgeText = isFr ? 'Pharmacies à proximité' : 'Nearby Pharmacies';
      badgeIcon = Icons.location_on_rounded;
      badgeColor = AppColors.primary;
    } else if (index == 1) {
      imagePath = 'assets/images/onboarding_order_medicine.jpg';
      badgeText = isFr ? 'Stock & Ordonnances' : 'Verified Stock & Rx';
      badgeIcon = Icons.verified_rounded;
      badgeColor = const Color(0xFF2563EB);
    } else {
      imagePath = 'assets/images/onboarding_fast_delivery.jpg';
      badgeText = isFr ? 'Livraison Express ~30 min' : 'Express Delivery ~30 min';
      badgeIcon = Icons.flash_on_rounded;
      badgeColor = const Color(0xFFD97706);
    }

    return Container(
      width: 290,
      height: 215,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
            // Bottom gradient overlay to make badge pop
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 70,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            // Floating badge over image
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        badgeText,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
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
