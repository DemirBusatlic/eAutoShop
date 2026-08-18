import 'dart:convert';

import 'package:eautoshop_mobile/models/order/order.dart';
import 'package:eautoshop_mobile/models/order/order_insert.dart';
import 'package:eautoshop_mobile/models/order/order_search_object.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';
import 'package:eautoshop_mobile/utilities/custom_exception.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class OrderProvider extends BaseProvider<Order, OrderInsert> {
  List<Order> orders = [];
  int countOfItems = 0;
  bool isLoading = false;

  OrderProvider() : super('Order');

  Future<void> getByClient({
    required int pageNumber,
    required int pageSize,
    OrderSearchObject? orderSearch,
  }) async {
    isLoading = true;
    notifyListeners();

    final Map<String, dynamic> queryParams = {
      if (orderSearch != null) ...orderSearch.toJson(),
      'Page': pageNumber,
      'PageSize': pageSize,
    };

    try {
      final SearchResult<Order> searchResult = await get(
        customEndpoint: 'GetByClient',
        filter: queryParams,
        fromJson: (json) => Order.fromJson(json),
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

  Future<Order> insertOrder(OrderInsert order) async {
    final Order createdOrder = await _createOrder(order);

    final int totalAmountInCents = (createdOrder.totalAmount * 100).round();

    final paymentIntent = await _createPaymentIntent(
      createdOrder.id,
      totalAmountInCents,
    );

    final String clientSecret = paymentIntent['clientSecret'] as String;

    final String paymentIntentId = paymentIntent['paymentIntentId'] as String;

    try {
      await _confirmPayment(clientSecret);

      final Order paidOrder = await _updatePaymentStatus(
        createdOrder.id,
        paymentIntentId,
        successful: true,
      );

      notifyListeners();
      return paidOrder;
    } catch (_) {
      try {
        await _updatePaymentStatus(
          createdOrder.id,
          paymentIntentId,
          successful: false,
        );
      } catch (_) {
        // Glavna greška je neuspjelo Stripe plaćanje.
      }

      throw CustomException(
        'Payment was not successful. The order was saved as a failed payment.',
      );
    }
  }

  Future<Order> _createOrder(OrderInsert order) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint'),
        headers: await createHeaders(),
        body: jsonEncode(order.toJson()),
      );

      if (!_isSuccessful(response.statusCode)) {
        handleHttpError(response);
      }

      return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(
    int orderId,
    int totalAmount,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}/Payment/CreatePaymentIntent'),
        headers: await createHeaders(),
        body: jsonEncode({'orderId': orderId, 'totalAmount': totalAmount}),
      );

      if (!_isSuccessful(response.statusCode)) {
        handleHttpError(response);
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException('Payment could not be initialized.');
    }
  }

  Future<void> _confirmPayment(String clientSecret) async {
    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: const PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(),
      ),
    );
  }

  Future<Order> _updatePaymentStatus(
    int orderId,
    String paymentIntentId, {
    required bool successful,
  }) async {
    final endpointSuffix = successful
        ? 'AddSuccessfulPayment'
        : 'AddFailedPayment';

    final response = await http.put(
      Uri.parse(
        '${BaseProvider.baseUrl}/$endpoint/'
        '$endpointSuffix/$orderId/$paymentIntentId',
      ),
      headers: await createHeaders(),
    );

    if (!_isSuccessful(response.statusCode)) {
      handleHttpError(response);
    }

    return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> cancel(int id) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/Cancel/$id'),
        headers: await createHeaders(),
      );

      if (!_isSuccessful(response.statusCode)) {
        handleHttpError(response);
      }

      notifyListeners();
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<void> softDelete(int id) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/SoftDelete/$id'),
        headers: await createHeaders(),
      );

      if (!_isSuccessful(response.statusCode)) {
        handleHttpError(response);
      }

      notifyListeners();
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  bool _isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
