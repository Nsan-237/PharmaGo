import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/pending_order_provider.dart';

enum MockConfirmationResult { pending, confirmed, rejected }

class OrderPendingConfirmationScreen extends ConsumerStatefulWidget {
  const OrderPendingConfirmationScreen({super.key});

  @override
  ConsumerState<OrderPendingConfirmationScreen> createState() =>
      _OrderPendingConfirmationScreenState();
}

class _OrderPendingConfirmationScreenState
    extends ConsumerState<OrderPendingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final MockConfirmationResult _mockState = MockConfirmationResult.pending;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate human-in-the-loop pharmacist verification transition:
    // In production, this screen listens to WebSocket / Push notification events
    // triggered by the pharmacist/cashier confirming in `pharmago_web`.
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_mockState == MockConfirmationResult.pending) {
        // Auto-navigate to Order Confirmed once verified by pharmacist
        context.go('/order-confirmed');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isFr = lang == AppLanguage.fr;
    final auth = ref.watch(authProvider);
    final pendingOrder = ref.watch(pendingOrderProvider);
    final clientName = auth.isAuthenticated && auth.fullName.isNotEmpty ? auth.fullName : 'Client';
    final clientPhone = auth.phone.isNotEmpty ? auth.phone : '+237 6xx xx xx xx';
    final clientInitials = auth.initials;

    // Dynamic values from the order flow (fallback to sensible defaults for demo)
    final drugName = pendingOrder?.drugName ?? 'Médicament commandé';
    final drugLabel = pendingOrder?.drugLabel ?? drugName;
    final pharmacyName = pendingOrder?.pharmacyName ?? 'Pharmacie du Centre';
    final total = pendingOrder?.total ?? 2200;
    final unitPrice = pendingOrder?.unitPrice ?? 1200;
    final quantity = pendingOrder?.quantity ?? 1;
    final totalStr = '${(total).toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';
    final unitPriceStr = '${(unitPrice * quantity).toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          isFr ? 'Statut de la Commande' : 'Order Status',
          style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Prominent Waiting / Status Hero Banner ──
            if (_mockState == MockConfirmationResult.pending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3DC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8A33D).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A33D),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFE8A33D).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.hourglass_top_rounded,
                              color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFr
                          ? 'En attente de confirmation du pharmacien...'
                          : 'Waiting for pharmacist confirmation...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isFr
                          ? 'Le pharmacien vérifie manuellement la disponibilité réelle des médicaments dans l\'officine avant validation.'
                          : 'The pharmacist is manually checking real shelf stock in the dispensary before finalizing.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFB45309),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const SizedBox(
                      width: 140,
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFFFDE68A),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFE8A33D)),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                    ),
                  ],
                ),
              )
            else if (_mockState == MockConfirmationResult.rejected)
              // Rejected State Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.cancel_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isFr
                          ? 'Médicament non disponible'
                          : 'Pharmacy could not confirm this item',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFr
                          ? 'L\'officine a vérifié et ne dispose pas du stock requis.'
                          : 'The pharmacy checked physical stock and this item is currently unavailable.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF991B1B)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/search-results'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text(
                          isFr
                              ? 'Chercher d\'autres pharmacies'
                              : 'Search other pharmacies',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            // ── 2. Stepper Progress ──
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
                  _StepRow(
                    isDone: true,
                    title: isFr ? '1. Demande envoyée' : '1. Order Sent',
                    subtitle: isFr
                        ? 'Transmise à Pharmacie du Centre'
                        : 'Sent to Pharmacie du Centre',
                  ),
                  _StepRow(
                    isDone: false,
                    isActive: true,
                    title: isFr
                        ? '2. Vérification physique du stock'
                        : '2. Physical Stock Verification',
                    subtitle: isFr
                        ? 'Contrôle humain par le pharmacien'
                        : 'Human-in-the-loop pharmacist check',
                  ),
                  _StepRow(
                    isDone: false,
                    isLast: true,
                    title: isFr
                        ? '3. Préparation & Livraison'
                        : '3. Preparation & Delivery',
                    subtitle: isFr
                        ? 'Attribution du livreur'
                        : 'Delivery agent assignment',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── 3. Read-Only Order Summary Block ──
            Text(
              isFr ? 'Récapitulatif de la commande' : 'Order Summary',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),

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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pharmacyName,
                                style: GoogleFonts.sora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark),
                              ),
                              Text(
                                'Order #PGO-4587',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        totalStr,
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),

                  // Drug Item
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        drugLabel,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark),
                      ),
                      Text(
                        'x$quantity • $unitPriceStr',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textBody),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Delivery Fee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isFr ? 'Livraison à Domicile' : 'Home Delivery',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                      Text(
                        '1 000 FCFA',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),

                  // Attached Prescription
                  Row(
                    children: [
                      const Icon(Icons.attach_file_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'prescription.jpg (0.8 MB)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── 4. Customer Info (Read-Only) ──
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
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(clientInitials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                        Text(
                          '$clientPhone • Bastos, Yaoundé',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
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

class _StepRow extends StatelessWidget {
  final bool isDone;
  final bool isActive;
  final bool isLast;
  final String title;
  final String subtitle;

  const _StepRow({
    required this.isDone,
    this.isActive = false,
    this.isLast = false,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primary
                        : (isActive
                            ? const Color(0xFFE8A33D)
                            : AppColors.border),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 11, color: Colors.white)
                        : (isActive
                            ? const SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : null),
                  ),
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isActive || isDone ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF92400E)
                          : (isDone ? AppColors.textDark : AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted),
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
