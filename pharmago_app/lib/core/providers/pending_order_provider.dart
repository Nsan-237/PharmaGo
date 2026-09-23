import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the details of the last drug order initiated by the user.
/// Used by payment and confirmation screens to show the correct drug name
/// without hardcoding placeholders.
class PendingOrderDetails {
  final String drugName;
  final int quantity;
  final int unitPrice;
  final String pharmacyName;
  final String deliveryOption; // 'home' | 'pickup'
  final int total;

  const PendingOrderDetails({
    required this.drugName,
    required this.quantity,
    required this.unitPrice,
    required this.pharmacyName,
    required this.deliveryOption,
    required this.total,
  });

  String get drugLabel => quantity > 1 ? '$drugName (x$quantity)' : drugName;
}

class PendingOrderNotifier extends StateNotifier<PendingOrderDetails?> {
  PendingOrderNotifier() : super(null);

  void set(PendingOrderDetails details) {
    state = details;
  }

  void clear() {
    state = null;
  }
}

final pendingOrderProvider =
    StateNotifierProvider<PendingOrderNotifier, PendingOrderDetails?>(
  (ref) => PendingOrderNotifier(),
);
