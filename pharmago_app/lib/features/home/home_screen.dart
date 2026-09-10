import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/widgets/adaptive_map_view.dart';
import '../../core/widgets/skeleton_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  bool _showSkeleton = true;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Simulate a brief "loading" before revealing real content
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showSkeleton = false);
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  // Returns a delayed fade+slide animation for staggered children
  Animation<double> _staggeredFade(int index) {
    final start = (index * 0.12).clamp(0.0, 0.75);
    final end = (start + 0.35).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Header Bar ──
              FadeTransition(
                opacity: _staggeredFade(0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Official Brand Logo + Name (Well seen)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 38,
                              width: 38,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Pharma Finder Go',
                                style: GoogleFonts.sora(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                isFr ? 'Cameroun • 24h/24' : 'Cameroon • 24/7',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Location pill + Language Switcher
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  context.tr('home.location', ref: ref),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            avatar: Text(isFr ? '🇫🇷' : '🇬🇧',
                                style: const TextStyle(fontSize: 11)),
                            label: Text(
                              isFr ? 'FR' : 'EN',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              ref
                                  .read(localeProvider.notifier)
                                  .toggleLanguage();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Greeting Text ──
              FadeTransition(
                opacity: _staggeredFade(1),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('home.greeting', ref: ref),
                        style: GoogleFonts.sora(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('home.subtitle', ref: ref),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 3. Search Bar ──
              FadeTransition(
                opacity: _staggeredFade(2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => context.go('/search-results'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppColors.textMuted, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('home.searchHint', ref: ref),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── 4. Quick Action 4-Grid (staggered) ──
              FadeTransition(
                opacity: _staggeredFade(3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickActionButton(
                        icon: Icons.medication_liquid_rounded,
                        label: context.tr('home.actionSearchDrug', ref: ref),
                        onTap: () => context.go('/search-results'),
                        delay: 0,
                        controller: _staggerController,
                      ),
                      _QuickActionButton(
                        icon: Icons.upload_file_rounded,
                        label: context.tr('home.actionUploadRx', ref: ref),
                        onTap: () => context.go('/request-order'),
                        delay: 1,
                        controller: _staggerController,
                      ),
                      _QuickActionButton(
                        icon: Icons.assignment_outlined,
                        label: context.tr('home.actionMyOrders', ref: ref),
                        onTap: () => context.go('/orders'),
                        delay: 2,
                        controller: _staggerController,
                      ),
                      _QuickActionButton(
                        icon: Icons.favorite_border_rounded,
                        label: context.tr('home.actionHealthTips', ref: ref),
                        onTap: () => context.go('/health-tips'),
                        delay: 3,
                        controller: _staggerController,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── 5. AI Symptom Checker Banner Card ──
              FadeTransition(
                opacity: _staggeredFade(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006C59), Color(0xFF008A70)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                                Icons.face_retouching_natural_rounded,
                                color: Colors.white,
                                size: 32),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('home.symptomCheckerTitle',
                                    ref: ref),
                                style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isFr
                                    ? 'Suggestions indicatives\n(Ne remplace pas un médecin)'
                                    : 'Get advisory suggestions\n(Does not replace a doctor)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Try Button
                        GestureDetector(
                          onTap: () => context.go('/symptom-checker'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.tr('home.tryNow', ref: ref),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 14, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── 5b. Popular Medicines Section with Real Images ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFr ? 'Médicaments populaires' : 'Popular Medicines',
                      style: GoogleFonts.sora(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/search-results'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.tr('home.seeAll', ref: ref),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Horizontal Medicines List with Real Images
              SizedBox(
                height: 190,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: mockPopularDrugs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final drug = mockPopularDrugs[index];
                    return _PopularDrugCard(drug: drug, isFr: isFr);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── 6. Nearby Pharmacies Section Header ──
              FadeTransition(
                opacity: _staggeredFade(5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('home.nearbyTitle', ref: ref),
                        style: GoogleFonts.sora(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/search-results'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          context.tr('home.seeAll', ref: ref),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 7. Adaptive Map Preview (Online Google Maps / Offline Vector) ──
              FadeTransition(
                opacity: _staggeredFade(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AdaptiveMapView(
                    height: 135,
                    title: 'Pharmacie Centrale',
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 8. Pharmacy Cards: skeleton → real content ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _showSkeleton
                    ? Padding(
                        key: const ValueKey('skeleton'),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const SkeletonPharmacyList(count: 3),
                      )
                    : FadeTransition(
                        key: const ValueKey('real'),
                        opacity: _staggeredFade(7),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mockPharmacies.take(5).length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final pharmacy = mockPharmacies[index];
                            return _PharmacyCardHome(
                                pharmacy: pharmacy, isFr: isFr);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Button — with individual stagger scale+fade
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int delay;
  final AnimationController controller;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final start = (0.3 + delay * 0.08).clamp(0.0, 0.9);
    final end = (start + 0.25).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: anim,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pharmacy Card — Richer shadows + open/duty badge
// ─────────────────────────────────────────────────────────────────────────────
class _PharmacyCardHome extends StatelessWidget {
  final PharmacyModel pharmacy;
  final bool isFr;

  const _PharmacyCardHome({required this.pharmacy, required this.isFr});

  @override
  Widget build(BuildContext context) {
    // Generate distinct color and icon based on pharmacy name
    final isYaounde = pharmacy.city == 'Yaoundé';
    final isDonBosco = pharmacy.name.contains('Don Bosco');

    return InkWell(
      onTap: () => context.go('/pharmacy-details'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDonBosco ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
            width: isDonBosco ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDonBosco
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Distinctive Pharmacy Brand Badge / Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDonBosco
                      ? [const Color(0xFF0F766E), const Color(0xFF0D9488)]
                      : isYaounde
                          ? [const Color(0xFF1E40AF), const Color(0xFF3B82F6)]
                          : [const Color(0xFF047857), const Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (isDonBosco ? const Color(0xFF0F766E) : (isYaounde ? const Color(0xFF1E40AF) : const Color(0xFF047857)))
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 28),
                  if (pharmacy.isOnDuty)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pharmacy.name,
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // City Tag Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isYaounde ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isYaounde ? const Color(0xFF93C5FD) : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Text(
                          pharmacy.city,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isYaounde ? const Color(0xFF1D4ED8) : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pharmacy.address,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Rating
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(
                        '${pharmacy.rating}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${pharmacy.distanceKm} km',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textBody),
                      ),
                      const SizedBox(width: 6),
                      // Open/closed badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: pharmacy.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pharmacy.isOpen
                              ? (isFr ? 'Ouvert' : 'Open')
                              : (isFr ? 'Fermé' : 'Closed'),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: pharmacy.isOpen ? AppColors.primary : AppColors.error,
                          ),
                        ),
                      ),
                      if (pharmacy.isOnDuty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isFr ? 'De garde' : 'On duty',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Arrow button to view pharmacy details
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popular Drug Card — Rich Product Image + Price + Direct Order Action
// ─────────────────────────────────────────────────────────────────────────────
class _PopularDrugCard extends StatelessWidget {
  final DrugModel drug;
  final bool isFr;

  const _PopularDrugCard({required this.drug, required this.isFr});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/request-order'),
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Product Image Container
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 82,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: drug.imageUrl.isNotEmpty
                    ? Image.network(
                        drug.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.medication_rounded,
                              color: AppColors.primary, size: 36),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.medication_rounded,
                            color: AppColors.primary, size: 36),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Drug Name
            Text(
              drug.name,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Category
            Text(
              drug.category,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Price + Add Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${drug.price} F',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add_shopping_cart_rounded,
                      size: 14, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
