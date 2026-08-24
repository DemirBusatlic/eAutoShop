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
    try {
      final Order createdOrder = await _createOrder(order);

      final paymentIntent = await _createPaymentIntent(createdOrder.id);

      final clientSecret = paymentIntent['clientSecret'] as String?;

      if (clientSecret == null || clientSecret.trim().isEmpty) {
        throw CustomException('Stripe client secret nije pronađen.');
      }

      try {
        await _confirmPayment(clientSecret);
      } on StripeException catch (error) {
        final message =
            error.error.localizedMessage ?? 'Plaćanje nije završeno.';

        throw CustomException(message);
      } catch (error) {
        throw CustomException('Plaćanje nije završeno: $error');
      }

      try {
        final paidOrder = await _verifyPayment(createdOrder.id);

        notifyListeners();

        return paidOrder;
      } catch (error) {
        throw CustomException(
          'Stripe plaćanje je poslano, ali server nije '
          'mogao potvrditi rezultat: $error',
        );
      }
    } on CustomException {
      rethrow;
    } catch (error) {
      throw CustomException('Neočekivana greška prilikom naručivanja: $error');
    }
  }

  Future<Order> _createOrder(OrderInsert order) async {
    try {
      final url = Uri.parse('${BaseProvider.baseUrl}/$endpoint');

      final response = await http.post(
        url,
        headers: await createHeaders(),
        body: jsonEncode(order.toJson()),
      );

      if (!_isSuccessful(response.statusCode)) {
        handleHttpError(response);
      }

      if (response.body.isEmpty) {
        throw CustomException('Server nije vratio kreiranu narudžbu.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return Order.fromJson(data);
    } on CustomException {
      rethrow;
    } catch (error) {
      throw CustomException('Greška prilikom kreiranja narudžbe: $error');
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}/Payment/CreatePaymentIntent'),
        headers: await createHeaders(),
        body: jsonEncode({'orderId': orderId}),
      );

      if (!_isSuccessful(response.statusCode)) {
        handleHttpError(response);
      }

      if (response.body.isEmpty) {
        throw CustomException('Server nije vratio podatke za plaćanje.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final clientSecret = data['clientSecret'];

      if (clientSecret == null || clientSecret.toString().trim().isEmpty) {
        throw CustomException('Server nije vratio Stripe client secret.');
      }

      return data;
    } on CustomException {
      rethrow;
    } catch (error) {
      throw CustomException('Plaćanje nije moguće inicijalizovati: $error');
    }
  }

  Future<Order> _verifyPayment(int orderId) async {
    try {
      final url = Uri.parse(
        '${BaseProvider.baseUrl}/Payment/'
        'VerifyPayment/$orderId',
      );

      final response = await http.post(url, headers: await createHeaders());

      if (!_isSuccessful(response.statusCode)) {
        handleHttpError(response);
      }

      if (response.body.isEmpty) {
        throw CustomException('Server nije vratio potvrđenu narudžbu.');
      }

      return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on CustomException {
      rethrow;
    } catch (error) {
      throw CustomException(
        'Server trenutno ne može potvrditi plaćanje: $error',
      );
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
