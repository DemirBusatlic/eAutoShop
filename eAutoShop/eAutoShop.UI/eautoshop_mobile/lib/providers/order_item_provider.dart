import 'package:eautoshop_mobile/models/order_item/order_item.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class OrderItemProvider extends BaseProvider<OrderItem, OrderItem> {
  List<OrderItem> items = [];
  bool isLoading = false;

  OrderItemProvider() : super('OrderItem');

  Future<List<OrderItem>> getByOrder(int orderId) async {
    isLoading = true;
    notifyListeners();

    try {
      final searchResult = await get(
        filter: {'OrderId': orderId, 'Page': 1, 'PageSize': 100},
        fromJson: OrderItem.fromJson,
      );

      items = searchResult.result;
      return List<OrderItem>.unmodifiable(items);
    } catch (_) {
      items = [];
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
