import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/widgets/adaptive_map_view.dart';
import '../../core/widgets/app_toast.dart';

class PharmacyDetailsScreen extends ConsumerWidget {
  const PharmacyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;
    final pharmacy = mockPharmacies.first;
    final drug = mockPopularDrugs.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.go('/search-results'),
        ),
        title: Text(
          context.tr('pharma.detailsTitle', ref: ref),
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Pharmacy Main Header Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy.name,
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pharmacy.distanceKm} km away • ${pharmacy.openingHours}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textBody),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                                const SizedBox(width: 3),
                                Text(
                                  '${pharmacy.rating} (${pharmacy.reviewCount})',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),

                  // Quick Action Buttons: Call, Directions, Website
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PharmaActionButton(
                        icon: Icons.phone_outlined,
                        label: context.tr('pharma.call', ref: ref),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    isFr ? 'Appeler la pharmacie' : 'Call Pharmacy',
                                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              content: Text(
                                '${pharmacy.name}\n${pharmacy.phone}',
                                style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(isFr ? 'Fermer' : 'Close'),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    AppToast.show(
                                      context,
                                      message: isFr
                                          ? 'Numérotation de ${pharmacy.phone}...'
                                          : 'Dialing ${pharmacy.phone}...',
                                      type: ToastType.info,
                                    );
                                  },
                                  icon: const Icon(Icons.call, color: Colors.white, size: 16),
                                  label: Text(
                                    isFr ? 'Composer' : 'Dial',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _PharmaActionButton(
                        icon: Icons.directions_outlined,
                        label: context.tr('pharma.directions', ref: ref),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (bCtx) => Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pharmacy.name,
                                              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                            ),
                                            Text(
                                              '${pharmacy.address} • ${pharmacy.city}',
                                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  // Time and distance estimation pill row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDF4),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFBBF7D0)),
                                          ),
                                          child: Column(
                                            children: [
                                              const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 20),
                                              const SizedBox(height: 4),
                                              Text(
                                                '~${(pharmacy.distanceKm * 3.5).round()} min',
                                                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                              ),
                                              Text(isFr ? 'En voiture' : 'By car', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Column(
                                            children: [
                                              const Icon(Icons.directions_walk_rounded, color: Color(0xFF2563EB), size: 20),
                                              const SizedBox(height: 4),
                                              Text(
                                                '~${(pharmacy.distanceKm * 12).round()} min',
                                                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF)),
                                              ),
                                              Text(isFr ? 'À pied' : 'Walking', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: Column(
                                            children: [
                                              const Icon(Icons.straighten_rounded, color: Color(0xFFD97706), size: 20),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${pharmacy.distanceKm} km',
                                                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                                              ),
                                              Text(isFr ? 'Distance' : 'Distance', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    isFr ? 'Étapes de l\'itinéraire :' : 'Route steps:',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRouteStep(
                                    '1',
                                    isFr ? 'Partir de votre position actuelle' : 'Start from your current location',
                                    isFr ? 'Suivre l\'axe principal vers ${pharmacy.city}' : 'Follow main axis toward ${pharmacy.city}',
                                  ),
                                  _buildRouteStep(
                                    '2',
                                    isFr ? 'Rejoindre ${pharmacy.address}' : 'Head towards ${pharmacy.address}',
                                    '${pharmacy.distanceKm} km',
                                  ),
                                  _buildRouteStep(
                                    '3',
                                    isFr ? 'Destination atteinte à droite : ${pharmacy.name}' : 'Destination reached on right: ${pharmacy.name}',
                                    pharmacy.openingHours,
                                    isLast: true,
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(bCtx);
                                        AppToast.show(
                                          context,
                                          message: isFr
                                              ? 'Navigation GPS activée vers ${pharmacy.name}'
                                              : 'GPS navigation active towards ${pharmacy.name}',
                                          type: ToastType.success,
                                        );
                                      },
                                      icon: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
                                      label: Text(
                                        isFr ? 'Démarrer la navigation GPS' : 'Start GPS Navigation',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _PharmaActionButton(
                        icon: Icons.language_rounded,
                        label: context.tr('pharma.website', ref: ref),
                        onTap: () {
                          AppToast.show(
                            context,
                            message: '${pharmacy.website}',
                            type: ToastType.info,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 2. Medication Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF7DD3FC)),
                    ),
                    child: const Center(
                      child: Icon(Icons.vaccines_rounded, color: Color(0xFF0284C7), size: 30),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              drug.name,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                drug.dosage,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isFr
                              ? 'En Stock - ${drug.stockCount} boîtes disponibles'
                              : 'In Stock - ${drug.stockCount} boxes available',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isFr ? 'Prix : 1 200 FCFA' : 'Price: 1,200 FCFA',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 3. Route & ETA Section with Real OpenStreetMap ──
            Text(
              context.tr('pharma.routeAndEta', ref: ref),
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            AdaptiveMapView(
              height: 175,
              showRoute: true,
              title: pharmacy.name,
              etaText: '25 - 35 min (8.2 km)',
            ),
          ],
        ),
      ),

      // ── Bottom Fixed Button: Request Order ──
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/request-order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: Text(
              context.tr('pharma.requestOrder', ref: ref),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PharmaActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PharmaActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildRouteStep(String stepNumber, String title, String subtitle, {bool isLast = false}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isLast ? AppColors.success : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 26,
              color: Colors.grey.shade300,
            ),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
