import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class MapPreviewCard extends StatelessWidget {
  final double height;
  final String? title;
  final bool showRoute;
  final String? etaText;
  final List<MapPinData>? pins;

  const MapPreviewCard({
    super.key,
    this.height = 140,
    this.title,
    this.showRoute = false,
    this.etaText,
    this.pins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Styled Map Background Grid & Roads Pattern
            CustomPaint(
              size: Size.infinite,
              painter: _MapCanvasPainter(showRoute: showRoute),
            ),

            // Top Left overlay badge if present
            if (title != null)
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
                        color: Colors.black.withValues(alpha: 0.06),
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
                        title!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Right ETA badge if present
            if (etaText != null)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    etaText!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Map Markers / Pins
            if (pins != null)
              ...pins!.map((p) => Positioned(
                    left: p.xPercent * (MediaQuery.of(context).size.width - 40),
                    top: p.yPercent * height,
                    child: _MapPinWidget(
                      isHighlighted: p.isHighlighted,
                      label: p.label,
                    ),
                  )),

            // Default sample pins if none provided
            if (pins == null) ...[
              const Positioned(
                left: 60,
                top: 35,
                child: _MapPinWidget(isHighlighted: true, label: 'Centrale'),
              ),
              const Positioned(
                left: 170,
                top: 75,
                child: _MapPinWidget(isHighlighted: false, label: 'Johnson'),
              ),
              const Positioned(
                right: 50,
                top: 40,
                child: _MapPinWidget(isHighlighted: false, label: 'St Claire'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MapPinData {
  final double xPercent;
  final double yPercent;
  final String label;
  final bool isHighlighted;

  const MapPinData({
    required this.xPercent,
    required this.yPercent,
    required this.label,
    this.isHighlighted = false,
  });
}

class _MapPinWidget extends StatelessWidget {
  final bool isHighlighted;
  final String label;

  const _MapPinWidget({required this.isHighlighted, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.primary : const Color(0xFF2563EB),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            isHighlighted ? Icons.local_pharmacy_rounded : Icons.location_on_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final bool showRoute;

  _MapCanvasPainter({required this.showRoute});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFD4E5DF)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background water/park shapes
    final parkPaint = Paint()..color = const Color(0xFFDFECE7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 20, size.width * 0.4, size.height * 0.6),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    // Draw main roads
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(size.width * 0.4, size.height * 0.2, size.width * 0.6, size.height * 0.7, size.width, size.height * 0.6);

    final path2 = Path()
      ..moveTo(size.width * 0.3, 0)
      ..cubicTo(size.width * 0.35, size.height * 0.5, size.width * 0.7, size.height * 0.5, size.width * 0.8, size.height);

    canvas.drawPath(path1, roadBorderPaint);
    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, roadBorderPaint);
    canvas.drawPath(path2, roadPaint);

    // If active delivery route
    if (showRoute) {
      final routePath = Path()
        ..moveTo(50, size.height * 0.65)
        ..cubicTo(size.width * 0.35, size.height * 0.3, size.width * 0.65, size.height * 0.6, size.width - 50, size.height * 0.4);

      canvas.drawPath(routePath, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
