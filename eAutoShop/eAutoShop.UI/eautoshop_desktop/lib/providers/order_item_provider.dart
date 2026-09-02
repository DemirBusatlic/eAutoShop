import 'package:eautoshop_desktop/models/order_item/order_item.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class OrderItemProvider extends BaseProvider<OrderItem, OrderItem> {
  OrderItemProvider() : super('OrderItem');

  List<OrderItem> orderItems = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getByOrder({required int orderId}) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<OrderItem> searchResult = await get(
        filter: {'OrderId': orderId},
        fromJson: OrderItem.fromJson,
      );

      orderItems = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      orderItems = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearOrderItems() {
    orderItems = [];
    countOfItems = 0;
    notifyListeners();
  }
}
