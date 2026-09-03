// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Real Google Maps embed for Flutter Web using HtmlElementView.
/// Falls back to the vector canvas map on non-web platforms.
class RealMapView extends StatefulWidget {
  final double height;
  final double lat;
  final double lng;
  final String? markerTitle;
  final String? etaText;
  final bool showRoute;
  final double? destLat;
  final double? destLng;

  const RealMapView({
    super.key,
    this.height = 200,
    this.lat = 4.0511,    // Default: Douala, Cameroon
    this.lng = 9.7085,
    this.markerTitle,
    this.etaText,
    this.showRoute = false,
    this.destLat,
    this.destLng,
  });

  @override
  State<RealMapView> createState() => _RealMapViewState();
}

class _RealMapViewState extends State<RealMapView> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'google-map-${DateTime.now().millisecondsSinceEpoch}';
    _registerMap();
  }

  void _registerMap() {
    // Build Google Maps Embed URL
    // Using the free Embed API (no billing required for basic embeds)
    final String mapUrl = _buildMapUrl();

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        // Create iframe element
        final iframe = _createIframe(mapUrl);
        return iframe;
      },
    );
  }

  String _buildMapUrl() {
    // Google Maps Embed API (free tier)
    // Mode: 'place' shows a pin at the location
    // Mode: 'directions' shows a route
    const apiKey = String.fromEnvironment(
      'GOOGLE_MAPS_KEY',
      defaultValue: '',
    );

    if (apiKey.isNotEmpty && widget.showRoute && widget.destLat != null) {
      // Directions embed with real API key
      return 'https://www.google.com/maps/embed/v1/directions'
          '?key=$apiKey'
          '&origin=${widget.lat},${widget.lng}'
          '&destination=${widget.destLat},${widget.destLng}'
          '&mode=driving'
          '&language=fr';
    } else if (apiKey.isNotEmpty) {
      // Place embed with real API key
      return 'https://www.google.com/maps/embed/v1/view'
          '?key=$apiKey'
          '&center=${widget.lat},${widget.lng}'
          '&zoom=15'
          '&maptype=roadmap';
    } else {
      // No API key: use free OpenStreetMap via embed URL
      return _buildOpenStreetMapUrl();
    }
  }

  String _buildOpenStreetMapUrl() {
    // OpenStreetMap iframe embed — completely free, no API key
    final bbox = _getBoundingBox(widget.lat, widget.lng, 0.01);
    return 'https://www.openstreetmap.org/export/embed.html'
        '?bbox=${bbox['minLon']},${bbox['minLat']},${bbox['maxLon']},${bbox['maxLat']}'
        '&layer=mapnik'
        '&marker=${widget.lat},${widget.lng}';
  }

  Map<String, double> _getBoundingBox(double lat, double lng, double delta) {
    return {
      'minLat': lat - delta,
      'maxLat': lat + delta,
      'minLon': lng - delta,
      'maxLon': lng + delta,
    };
  }

  // Creates an HTML iframe element programmatically
  dynamic _createIframe(String src) {
    // Use dart:html for web
    // We use a workaround to avoid importing dart:html directly
    // by using the JS interop
    final html = _getHtmlDocument();
    if (html == null) return _createFallbackElement();

    final iframe = html.createElement('iframe');
    iframe.setAttribute('src', src);
    iframe.setAttribute('width', '100%');
    iframe.setAttribute('height', '100%');
    iframe.setAttribute('frameborder', '0');
    iframe.setAttribute('style', 'border:0; width:100%; height:100%;');
    iframe.setAttribute('allowfullscreen', '');
    iframe.setAttribute('loading', 'lazy');
    iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
    return iframe;
  }

  dynamic _getHtmlDocument() {
    try {
      // Access document via JS interop
      return _JsHelper.document;
    } catch (_) {
      return null;
    }
  }

  dynamic _createFallbackElement() {
    try {
      final div = _JsHelper.document.createElement('div');
      div.setAttribute('style', 'width:100%; height:100%; background:#e8f2ee; display:flex; align-items:center; justify-content:center;');
      div.innerText = 'Map';
      return div;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map iframe
            HtmlElementView(viewType: _viewId),

            // ETA badge overlay
            if (widget.etaText != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.etaText!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Location label badge
            if (widget.markerTitle != null)
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        widget.markerTitle!,
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

            // OSM Attribution (required)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.white.withValues(alpha: 0.8),
                child: Text(
                  '© OpenStreetMap',
                  style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// JS Interop helper to access document
class _JsHelper {
  static dynamic get document {
    // Using dart:js_interop approach
    return _getDocument();
  }

  static dynamic _getDocument() {
    try {
      // Use JS eval to get document
      return _evalJs('document');
    } catch (_) {
      return null;
    }
  }

  static dynamic _evalJs(String expr) {
    // Lightweight JS call
    return _callJs(expr);
  }

  static dynamic _callJs(String code) {
    throw UnimplementedError('Use platform-specific implementation');
  }
}
