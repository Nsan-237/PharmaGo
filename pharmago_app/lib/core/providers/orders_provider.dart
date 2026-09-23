import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mock_data/mock_data.dart';
import '../network/api_client.dart';

class OrdersNotifier extends StateNotifier<List<ClientOrderModel>> {
  OrdersNotifier() : super(mockClientOrders);

  void addOrder(ClientOrderModel order) {
    state = [order, ...state];
  }

  /// Cancel a pending order locally and notify the server.
  Future<void> cancelOrder(String orderId) async {
    // Optimistic update
    state = state.map((o) => o.id == orderId
        ? ClientOrderModel(
            id: o.id,
            pharmacyName: o.pharmacyName,
            address: o.address,
            drugs: o.drugs,
            total: o.total,
            status: 'cancelled',
            createdAt: o.createdAt,
            estimatedTime: o.estimatedTime,
            isDelivery: o.isDelivery,
            deliveryAgent: o.deliveryAgent,
            deliveryAgentPhone: o.deliveryAgentPhone,
          )
        : o).toList();
    // Best-effort server call
    try {
      await ApiClient.instance.updateOrderStatus(orderId, {'status': 'annule'});
    } catch (_) {}
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<ClientOrderModel>>((ref) {
  return OrdersNotifier();
});
