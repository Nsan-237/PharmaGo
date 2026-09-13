import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mock_data/mock_data.dart';

class OrdersNotifier extends StateNotifier<List<ClientOrderModel>> {
  OrdersNotifier() : super(mockClientOrders);

  void addOrder(ClientOrderModel order) {
    state = [order, ...state];
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<ClientOrderModel>>((ref) {
  return OrdersNotifier();
});
