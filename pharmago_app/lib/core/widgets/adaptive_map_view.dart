import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'map_preview_card.dart';

/// Adaptive Map Component for PharmaGo.
/// ONLINE mode  → Real OpenStreetMap live tiles (free, no API key needed).
/// OFFLINE mode → Vector canvas fallback (works without internet).
/// The toggle chip lets you demo both modes to your teacher instantly.
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
    setState(() => _isOnline = !_isOnline);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            _isOnline ? const Color(0xFF006C59) : const Color(0xFF374151),
        content: Row(
          children: [
            Icon(
              _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isOnline
                    ? 'Carte en ligne activée (OpenStreetMap)'
                    : 'Mode hors-ligne activé (Carte vectorielle intégrée)',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
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
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ── Map Layer ──────────────────────────────────────────────────
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isOnline
                    ? _OsmMapTile(
                        key: const ValueKey('osm_map'),
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

            // ── Title Badge ────────────────────────────────────────────────
            if (widget.title != null)
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.primary),
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

            // ── Online / Offline Toggle Chip ───────────────────────────────
            Positioned(
              top: 10,
              right: 12,
              child: GestureDetector(
                onTap: _toggleNetworkMode,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isOnline
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFD1D5DB),
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
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF6B7280),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? 'OpenStreetMap · Live' : 'Hors-ligne',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isOnline
                              ? const Color(0xFF15803D)
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── ETA Badge ─────────────────────────────────────────────────
            if (widget.etaText != null)
              Positioned(
                bottom: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation_rounded,
                          size: 12, color: Colors.white),
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

            // ── OSM Attribution (required by OSM license) ─────────────────
            if (_isOnline)
              Positioned(
                bottom: 4,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: GoogleFonts.inter(
                      fontSize: 7,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Real OpenStreetMap Tile Widget ──────────────────────────────────────────

class _OsmMapTile extends StatelessWidget {
  final bool showRoute;
  final AnimationController pulseController;

  const _OsmMapTile({
    super.key,
    required this.showRoute,
    required this.pulseController,
  });

  // Douala, Cameroon — Akwa / Bonanjo district (pharmacy-dense area)
  static const _douala = LatLng(4.0511, 9.7679);
  static const _pharmacyLatLng = LatLng(4.0540, 9.7720);
  static const _userLatLng = LatLng(4.0495, 9.7655);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: _douala,
        initialZoom: 14.8,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        // ── OSM Base Tile Layer ─────────────────────────────────────────
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pharmago.app',
          tileBuilder: (context, tileWidget, tile) => tileWidget,
        ),

        // ── Delivery Route Polyline ─────────────────────────────────────
        if (showRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: const [
                  _userLatLng,
                  LatLng(4.0500, 9.7670),
                  LatLng(4.0515, 9.7690),
                  LatLng(4.0528, 9.7705),
                  _pharmacyLatLng,
                ],
                color: const Color(0xFF3B82F6),
                strokeWidth: 4.0,
                borderColor: const Color(0xFF1E40AF),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // ── Markers Layer ───────────────────────────────────────────────
        MarkerLayer(
          markers: [
            // User location marker
            Marker(
              point: _userLatLng,
              width: 40,
              height: 40,
              child: _UserLocationMarker(pulseController: pulseController),
            ),
            // Pharmacy pin marker
            const Marker(
              point: _pharmacyLatLng,
              width: 140,
              height: 58,
              child: _PharmacyMarker(),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Pulsing User Location Marker ────────────────────────────────────────────

class _UserLocationMarker extends StatelessWidget {
  final AnimationController pulseController;
  const _UserLocationMarker({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 28 + pulseController.value * 14,
            height: 28 + pulseController.value * 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B82F6)
                  .withValues(alpha: 0.25 * (1 - pulseController.value)),
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
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pharmacy Pin Marker ──────────────────────────────────────────────────────

class _PharmacyMarker extends StatelessWidget {
  const _PharmacyMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_pharmacy_rounded,
                  size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Pharmacie Centrale',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        // Pin tail
        Container(
          width: 2,
          height: 8,
          color: AppColors.primary,
        ),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
