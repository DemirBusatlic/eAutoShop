import 'dart:convert';

import 'package:eautoshop_desktop/models/order/order.dart';
import 'package:eautoshop_desktop/models/order/order_accept.dart';
import 'package:eautoshop_desktop/models/order/order_search_object.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class OrderProvider extends BaseProvider<Order, OrderAccept> {
  OrderProvider() : super('Order');

  List<Order> orders = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getForShop({
    required int page,
    required int pageSize,
    OrderSearchObject? search,
  }) async {
    isLoading = true;
    notifyListeners();

    final queryParameters = search?.toJson() ?? <String, dynamic>{};

    queryParameters['Page'] = page;
    queryParameters['PageSize'] = pageSize;

    try {
      final SearchResult<Order> searchResult = await get(
        customEndpoint: 'shop',
        filter: queryParameters,
        fromJson: Order.fromJson,
      );

      orders = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      orders = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptOrder({
    required int id,
    required OrderAccept request,
  }) async {
    await update(
      id: id,
      item: request,
      customEndpoint: 'Accept',
      toJson: (item) => item.toJson(),
    );
  }

  Future<void> rejectOrder(int id) async {
    await _executeAction(action: 'Reject', id: id);
  }

  Future<void> completeOrder(int id) async {
    await _executeAction(action: 'Complete', id: id);
  }

  Future<void> cancelOrder(int id) async {
    await _executeAction(action: 'Cancel', id: id);
  }

  Future<void> softDeleteOrder(int id) async {
    await _executeAction(action: 'SoftDelete', id: id);
  }

  Future<List<String>> getAllowedActions(int id) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${BaseProvider.baseUrl}/'
          '$endpoint/AllowedActions/$id',
        ),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        final data = jsonDecode(response.body) as List<dynamic>;

        return data.map((action) => action.toString()).toList();
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw const CustomException(
        'Nije moguće pristupiti serveru. '
        'Provjerite da li je API pokrenut.',
      );
    }
  }

  Future<void> _executeAction({required String action, required int id}) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/$action/$id'),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        notifyListeners();
        return;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw const CustomException(
        'Nije moguće pristupiti serveru. '
        'Provjerite da li je API pokrenut.',
      );
    }
  }

  bool _isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
