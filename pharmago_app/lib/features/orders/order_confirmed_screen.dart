import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class OrderConfirmedScreen extends ConsumerStatefulWidget {
  const OrderConfirmedScreen({super.key});

  @override
  ConsumerState<OrderConfirmedScreen> createState() =>
      _OrderConfirmedScreenState();
}

class _OrderConfirmedScreenState extends ConsumerState<OrderConfirmedScreen>
    with TickerProviderStateMixin {
  // Circle scale-in animation
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Check stroke draw animation
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  // Content fade-in animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Circle pops in
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // 2. Check draws in after circle appears
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOut,
    );

    // 3. Content fades in after check finishes
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Sequence the three animations
    _scaleController.forward().then((_) {
      _checkController.forward().then((_) {
        _fadeController.forward();
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          context.tr('order.confirmedTitle', ref: ref),
          style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // ── Animated Checkmark ──
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _checkAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _CheckPainter(progress: _checkAnimation.value),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Confirmation Text (fades in after check) ──
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      context.tr('order.confirmedHeadline', ref: ref),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('order.confirmedSubtitle', ref: ref),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textBody,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Payment reminder chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments_rounded, size: 13, color: Color(0xFF16A34A)),
                          const SizedBox(width: 5),
                          Text(
                            context.tr('order.confirmedPaymentStep', ref: ref),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Info Cards (fades in) ──
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // ETA Card
                    _InfoCard(
                      label: context.tr('order.estimatedDelivery', ref: ref),
                      value: '25 - 35 min',
                      icon: Icons.schedule_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Delivery Agent Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delivery_dining_rounded,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('order.deliveryAgent', ref: ref),
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Martin T.',
                                  style: GoogleFonts.sora(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  '+237 6 98 76 54 32',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textBody),
                                ),
                              ],
                            ),
                          ),
                          // Call button
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Action Buttons (fades in) ──
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Primary: Proceed to Payment
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/payment'),
                        icon: const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                        label: Text(
                          context.tr('order.proceedToPayment', ref: ref),
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                          shadowColor:
                              AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Secondary: Back to Home
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          context.tr('order.backToHome', ref: ref),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
// Custom check stroke painter — draws a ✓ stroke progressively
// ─────────────────────────────────────────────────────────────────────────────
class _CheckPainter extends CustomPainter {
  final double progress;

  const _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Define check path: from bottom-left corner up to middle, then up-right
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Check points (tuned for a 104px circle)
    final p1 = Offset(cx - 16, cy + 2);   // left bottom of check
    final p2 = Offset(cx - 4, cy + 14);   // middle point
    final p3 = Offset(cx + 18, cy - 14);  // top right

    final totalLength = _dist(p1, p2) + _dist(p2, p3);
    final drawn = totalLength * progress;

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    final seg1 = _dist(p1, p2);
    if (drawn <= seg1) {
      final t = drawn / seg1;
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
    } else {
      path.lineTo(p2.dx, p2.dy);
      final seg2Drawn = drawn - seg1;
      final seg2 = _dist(p2, p3);
      final t = (seg2Drawn / seg2).clamp(0.0, 1.0);
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * t,
        p2.dy + (p3.dy - p2.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  double _dist(Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    return (dx * dx + dy * dy) * 1.0; // return squared — relative proportion is enough
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable info card widget
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
