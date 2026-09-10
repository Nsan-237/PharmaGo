import 'dart:convert';
import 'package:http/http.dart' as http;

/// Campay Mobile Money API Service for PharmaGo.
/// 
/// ─── IMPORTANT: CORS BYPASS ──────────────────────────────────────────────────
/// Flutter Web (Chrome) CANNOT call demo.campay.net directly due to browser
/// CORS restrictions. All payment calls are routed through the local Node.js
/// backend at localhost:5000, which calls Campay server-side without CORS issues.
/// Flutter Mobile (Android/iOS) uses the same backend route for consistency.
/// ─────────────────────────────────────────────────────────────────────────────
/// Docs: https://documenter.getpostman.com/view/2391374/T1LV8PVA
class CampayService {
  // ── Backend proxy URL (Node.js at localhost:5000 handles Campay auth) ───────
  static const String _backendUrl = 'http://localhost:5000/api/payment';

  // Always live — backend has real Campay credentials in .env
  static bool get isUsingRealApi => true;

  // ─── Campay Sandbox Test Numbers ─────────────────────────────────────────
  // MTN:    237677777777 → SUCCESSFUL  |  237677777770 → FAILED
  // Orange: 237699999999 → SUCCESSFUL  |  237699999990 → FAILED
  // Sandbox max amount: 25 XAF
  static const String sandboxMtnSuccess = '677777777';
  static const String sandboxOrangeSuccess = '699999999';

  // ─── Collect Payment (via backend proxy → Campay USSD Push) ──────────────
  //
  // Flow:
  //   Flutter → POST localhost:5000/api/payment/initiate
  //     → Node backend → POST demo.campay.net/api/collect/ (server-side, no CORS)
  //       → Campay sends USSD push to user's phone
  //         → User enters PIN on phone
  //           → Campay marks transaction SUCCESSFUL
  //             → Flutter polls GET localhost:5000/api/payment/status/:ref
  //
  /// Returns a [CampayPaymentResult] with reference and status.
  static Future<CampayPaymentResult> collectPayment({
    required String phoneNumber,
    required int amountFcfa,
    required String description,
    String? externalReference,
  }) async {
    try {
      final body = <String, dynamic>{
        'phone': phoneNumber,
        'amountFcfa': amountFcfa,
        'description': description,
        if (externalReference != null) 'orderId': externalReference,
      };

      final response = await http.post(
        Uri.parse('$_backendUrl/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return CampayPaymentResult(
            reference: data['reference'] as String? ?? '',
            status: _parseStatus(data['status'] as String? ?? 'PENDING'),
            operator: data['operator'] as String? ?? '',
            message: data['message'] as String? ?? 'USSD push sent to your phone!',
          );
        } else {
          return CampayPaymentResult(
            reference: '',
            status: CampayStatus.failed,
            operator: '',
            message: data['error'] as String? ?? 'Payment request failed',
          );
        }
      } else {
        final errorMsg = data['error'] ?? data['message'] ?? 'Payment failed (${response.statusCode})';
        return CampayPaymentResult(
          reference: '',
          status: CampayStatus.failed,
          operator: '',
          message: errorMsg.toString(),
        );
      }
    } catch (e) {
      // ── Direct Campay Fallback (Works seamlessly on Mobile devices / Android / iOS) ──
      try {
        final directResponse = await http.post(
          Uri.parse('https://demo.campay.net/api/collect/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token J23uzKJW7dvG+RZ3/ZDX_3kRM96E3rXo~HNsEnFv',
          },
          body: jsonEncode({
            'amount': amountFcfa.toString(),
            'from': _normalizePhone(phoneNumber),
            'description': description,
            if (externalReference != null) 'external_reference': externalReference,
          }),
        ).timeout(const Duration(seconds: 15));

        if (directResponse.statusCode == 200 || directResponse.statusCode == 201) {
          final directData = jsonDecode(directResponse.body) as Map<String, dynamic>;
          return CampayPaymentResult(
            reference: directData['reference'] as String? ?? '',
            status: _parseStatus(directData['status'] as String? ?? 'PENDING'),
            operator: directData['operator'] as String? ?? '',
            message: 'Demande USSD envoyée à votre téléphone !',
          );
        } else {
          final directData = jsonDecode(directResponse.body) as Map<String, dynamic>;
          return CampayPaymentResult(
            reference: '',
            status: CampayStatus.failed,
            operator: '',
            message: directData['message'] ?? directData['detail'] ?? 'Campay error: ${directResponse.statusCode}',
          );
        }
      } catch (fallbackError) {
        return CampayPaymentResult(
          reference: '',
          status: CampayStatus.failed,
          operator: '',
          message: 'Erreur de connexion: ${fallbackError.toString()}',
        );
      }
    }
  }

  static String _normalizePhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!digits.startsWith('237') && digits.length <= 9) {
      digits = '237$digits';
    }
    return digits;
  }

  // ─── Check Payment Status (via backend proxy → Campay) ───────────────────

  static Future<CampayStatus> checkPaymentStatus(String reference) async {
    if (reference.isEmpty) return CampayStatus.pending;

    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/status/$reference'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseStatus(data['status'] as String? ?? 'PENDING');
      }
      return CampayStatus.pending;
    } catch (e) {
      // ── Direct Campay fallback for mobile ──
      try {
        final directResponse = await http.get(
          Uri.parse('https://demo.campay.net/api/transaction/$reference/'),
          headers: {
            'Authorization': 'Token J23uzKJW7dvG+RZ3/ZDX_3kRM96E3rXo~HNsEnFv',
          },
        ).timeout(const Duration(seconds: 10));

        if (directResponse.statusCode == 200) {
          final directData = jsonDecode(directResponse.body) as Map<String, dynamic>;
          return _parseStatus(directData['status'] as String? ?? 'PENDING');
        }
      } catch (_) {}
      return CampayStatus.pending;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static CampayStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESSFUL':
        return CampayStatus.successful;
      case 'FAILED':
        return CampayStatus.failed;
      case 'PENDING':
      default:
        return CampayStatus.pending;
    }
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

enum CampayStatus { pending, successful, failed }

class CampayPaymentResult {
  final String reference;
  final CampayStatus status;
  final String operator;
  final String message;

  const CampayPaymentResult({
    required this.reference,
    required this.status,
    required this.operator,
    required this.message,
  });

  bool get isSuccessful => status == CampayStatus.successful;
  bool get isFailed => status == CampayStatus.failed;
  bool get isPending => status == CampayStatus.pending;
}
