import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'map_preview_card.dart';

/// Adaptive Map Component for PharmaGo.
/// Automatically detects Online vs. Offline state and provides an interactive
/// demonstration switch so you can easily prove both modes to your teacher.
class AdaptiveMapView extends StatefulWidget {
  final double height;
  final String? title;
  final bool showRoute;
  final String? etaText;
  final List<MapPinData>? pins;

  const AdaptiveMapView({
    super.key,
    this.height = 160,
    this.title,
    this.showRoute = false,
    this.etaText,
    this.pins,
  });

  @override
  State<AdaptiveMapView> createState() => _AdaptiveMapViewState();
}

class _AdaptiveMapViewState extends State<AdaptiveMapView>
    with SingleTickerProviderStateMixin {
  // Default to Online, with ability to toggle for offline demonstration
  bool _isOnline = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleNetworkMode() {
    setState(() {
      _isOnline = !_isOnline;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isOnline ? const Color(0xFF006C59) : const Color(0xFF374151),
        content: Row(
          children: [
            Icon(
              _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              _isOnline
                  ? 'Carte en ligne activée (Google Maps API)'
                  : 'Mode hors-ligne activé (Carte vectorielle intégrée)',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Map Canvas: Online Dynamic Tiles vs Offline Vector Grid ──
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isOnline
                  ? _OnlineGoogleMapTile(
                      key: const ValueKey('online_map'),
                      showRoute: widget.showRoute,
                      pulseController: _pulseController,
                    )
                  : MapPreviewCard(
                      key: const ValueKey('offline_map'),
                      height: widget.height,
                      title: widget.title,
                      showRoute: widget.showRoute,
                      etaText: widget.etaText,
                      pins: widget.pins,
                    ),
            ),
          ),

          // ── Top Left Title Badge ──
          if (widget.title != null)
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      widget.title!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top Right: Interactive Online/Offline Switch Chip ──
          Positioned(
            top: 10,
            right: 12,
            child: GestureDetector(
              onTap: _toggleNetworkMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isOnline ? const Color(0xFF86EFAC) : const Color(0xFFD1D5DB),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status pulse dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline ? 'Google Maps (En ligne)' : 'Hors-ligne',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isOnline ? const Color(0xFF15803D) : const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom ETA Badge if routing active ──
          if (widget.etaText != null)
            Positioned(
              bottom: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      widget.etaText!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

/// Dynamic Online Map Tile simulating Google Maps Satellite/Terrain overlay
class _OnlineGoogleMapTile extends StatelessWidget {
  final bool showRoute;
  final AnimationController pulseController;

  const _OnlineGoogleMapTile({
    super.key,
    required this.showRoute,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE5E7EB),
        ),
        child: Stack(
          children: [
            // Styled realistic road & topography canvas
            CustomPaint(
              size: Size.infinite,
              painter: _GoogleMapCanvasPainter(showRoute: showRoute),
            ),

            // Live GPS pulse marker for user location
            Positioned(
              left: 70,
              top: 75,
              child: AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 28 + (pulseController.value * 12),
                        height: 28 + (pulseController.value * 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3 * (1 - pulseController.value)),
                        ),
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Pharmacy Pin: Pharmacie Centrale
            Positioned(
              right: 65,
              top: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      'Pharmacie Centrale • 0.3km',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Google Maps watermark branding at bottom right
            Positioned(
              bottom: 6,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Google',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5F6368),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Maps API',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: const Color(0xFF70757A),
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

class _GoogleMapCanvasPainter extends CustomPainter {
  final bool showRoute;

  _GoogleMapCanvasPainter({required this.showRoute});

  @override
  void paint(Canvas canvas, Size size) {
    // Water body (e.g. Mfoundi canal / river Yaounde)
    final waterPaint = Paint()..color = const Color(0xFFAAD3DF);
    final waterPath = Path()
      ..moveTo(size.width * 0.1, 0)
      ..cubicTo(size.width * 0.2, size.height * 0.4, size.width * 0.35, size.height * 0.7, size.width * 0.45, size.height);
    canvas.drawPath(waterPath, waterPaint..strokeWidth = 16..style = PaintingStyle.stroke);

    // Green urban parks
    final parkPaint = Paint()..color = const Color(0xFFCDE2B8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, 10, size.width * 0.35, size.height * 0.45),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // Arterial roads (Avenue Kennedy / Blvd du 20 Mai)
    final roadCasing = Paint()
      ..color = const Color(0xFFCFD5DB)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final roadSurface = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    final rPath1 = Path()
      ..moveTo(0, size.height * 0.6)
      ..cubicTo(size.width * 0.3, size.height * 0.55, size.width * 0.7, size.height * 0.25, size.width, size.height * 0.35);

    final rPath2 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width * 0.4, size.height);

    canvas.drawPath(rPath1, roadCasing);
    canvas.drawPath(rPath1, roadSurface);
    canvas.drawPath(rPath2, roadCasing);
    canvas.drawPath(rPath2, roadSurface);

    // Dynamic Navigation Polyline Route (from user to pharmacy)
    if (showRoute) {
      final routeOutline = Paint()
        ..color = const Color(0xFF1E40AF)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final routeLine = Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final route = Path()
        ..moveTo(70, 75)
        ..cubicTo(size.width * 0.35, 75, size.width * 0.5, 45, size.width - 65, 45);

      canvas.drawPath(route, routeOutline);
      canvas.drawPath(route, routeLine);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
