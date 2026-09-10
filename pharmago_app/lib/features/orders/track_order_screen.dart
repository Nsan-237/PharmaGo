import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/adaptive_map_view.dart';
import '../../core/widgets/app_toast.dart';

class TrackOrderScreen extends ConsumerWidget {
  const TrackOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.go('/orders'),
        ),
        title: Text(
          context.tr('track.title', ref: ref),
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map with Route & Live Driver Tracking (Adaptive Online / Offline)
            const AdaptiveMapView(
              height: 210,
              showRoute: true,
              title: 'Order #PGO-4587',
              etaText: '25 - 35 min',
            ),

            const SizedBox(height: 20),

            // Order Status Headline Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #PGO-4587',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tr('track.inProgress', ref: ref),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Vertical Stepper Timeline
                  _TimelineStep(
                    title: context.tr('track.stepConfirmed', ref: ref),
                    time: '10:30 AM',
                    isDone: true,
                    isFirst: true,
                  ),
                  _TimelineStep(
                    title: context.tr('track.stepPreparing', ref: ref),
                    time: '10:35 AM',
                    isDone: true,
                  ),
                  _TimelineStep(
                    title: context.tr('track.stepOutForDelivery', ref: ref),
                    time: '10:45 AM',
                    isDone: true,
                    isCurrent: true,
                  ),
                  _TimelineStep(
                    title: context.tr('track.stepDelivered', ref: ref),
                    time: context.tr('track.pending', ref: ref),
                    isDone: false,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Pharmacy Card (Dispatched from) ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pharmacie Centrale',
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Avenue Kennedy, Douala • +237 222 23 11 60',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                      child: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 18),
                    ),
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: isFr ? 'Appel vers Pharmacie Centrale (+237 222 23 11 60)...' : 'Calling Pharmacie Centrale (+237 222 23 11 60)...',
                        type: ToastType.info,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Delivery Agent Card with Call & Live Message ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF2563EB), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Martin T.',
                              style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isFr ? 'En route' : 'On the way',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+237 6 98 76 54 32',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),

                  // Call Driver Action
                  IconButton(
                    tooltip: isFr ? 'Appeler le livreur' : 'Call delivery driver',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Row(
                            children: [
                              const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                isFr ? 'Appeler Martin T.' : 'Call Martin T.',
                                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          content: Text(
                            isFr
                                ? 'Livreur PharmaGo pour la commande #PGO-4587\nNuméro : +237 6 98 76 54 32'
                                : 'PharmaGo delivery driver for order #PGO-4587\nPhone: +237 6 98 76 54 32',
                            style: GoogleFonts.inter(fontSize: 14, height: 1.4),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(isFr ? 'Annuler' : 'Cancel'),
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
                                  message: isFr ? 'Composition du +237 6 98 76 54 32...' : 'Dialing +237 6 98 76 54 32...',
                                  type: ToastType.info,
                                );
                              },
                              icon: const Icon(Icons.call, color: Colors.white, size: 16),
                              label: Text(
                                isFr ? 'Appeler' : 'Call',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                      child: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 18),
                    ),
                  ),

                  // Message Driver Action
                  IconButton(
                    tooltip: isFr ? 'Envoyer un message' : 'Message driver',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (ctx) => Padding(
                          padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isFr ? 'Message à Martin T. (Livreur)' : 'Message Martin T. (Driver)',
                                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    label: Text(isFr ? 'Où êtes-vous ?' : 'Where are you?'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      AppToast.show(context, message: isFr ? 'Message envoyé au livreur' : 'Message sent to driver', type: ToastType.success);
                                    },
                                  ),
                                  ActionChip(
                                    label: Text(isFr ? 'Je suis au portail' : 'I am at the gate'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      AppToast.show(context, message: isFr ? 'Message envoyé au livreur' : 'Message sent to driver', type: ToastType.success);
                                    },
                                  ),
                                  ActionChip(
                                    label: Text(isFr ? 'Sonnez à la porte B' : 'Ring at Door B'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      AppToast.show(context, message: isFr ? 'Message envoyé au livreur' : 'Message sent to driver', type: ToastType.success);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF0284C7), size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Action: Go to Payment if needed
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/payment'),
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: Text(
              isFr ? 'Voir les détails de paiement' : 'View Payment Details',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String time;
  final bool isDone;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.time,
    required this.isDone,
    this.isCurrent = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Dot & Line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? AppColors.primary : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? AppColors.primary : AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Title & Timestamp
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                      color: isDone ? AppColors.textDark : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isCurrent ? AppColors.primary : AppColors.textMuted,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
