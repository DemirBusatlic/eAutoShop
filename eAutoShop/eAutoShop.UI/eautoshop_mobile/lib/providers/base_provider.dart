import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:eautoshop_mobile/constants.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/utilities/custom_exception.dart';

abstract class BaseProvider<T, TInsertUpdate> with ChangeNotifier {
  static const String baseUrl = 'http://${ApiHost.address}:${ApiHost.port}';

  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String endpoint;

  BaseProvider(this.endpoint);

  Future<Map<String, String>> createHeaders() async {
    final token = await storage.read(key: 'jwt_token');

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<SearchResult<T>> get({
    String customEndpoint = '',
    Map<String, dynamic>? filter,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final uri = _createUri(customEndpoint: customEndpoint, filter: filter);

      final response = await http.get(uri, headers: await createHeaders());

      if (_isSuccessful(response.statusCode)) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final resultData = data['result'] as List<dynamic>? ?? [];

        return SearchResult<T>(
          count: data['count'] as int? ?? resultData.length,
          result: resultData
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList(),
        );
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (e) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<T> getById({
    String customEndpoint = '',
    required int id,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${_createEndpoint(customEndpoint)}/$id');

      final response = await http.get(uri, headers: await createHeaders());

      if (_isSuccessful(response.statusCode)) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(data);
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (e) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<void> insert(
    TInsertUpdate item, {
    String customEndpoint = '',
    required Map<String, dynamic> Function(TInsertUpdate) toJson,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_createEndpoint(customEndpoint)),
        headers: await createHeaders(),
        body: jsonEncode(toJson(item)),
      );

      if (_isSuccessful(response.statusCode)) {
        notifyListeners();
        return;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (e) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<void> update({
    required int id,
    required TInsertUpdate item,
    required Map<String, dynamic> Function(TInsertUpdate) toJson,
    String customEndpoint = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${_createEndpoint(customEndpoint)}/$id'),
        headers: await createHeaders(),
        body: jsonEncode(toJson(item)),
      );

      if (_isSuccessful(response.statusCode)) {
        notifyListeners();
        return;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (e) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<void> delete(int id, {String customEndpoint = ''}) async {
    try {
      final response = await http.delete(
        Uri.parse('${_createEndpoint(customEndpoint)}/$id'),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        notifyListeners();
        return;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (e) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Uri _createUri({String customEndpoint = '', Map<String, dynamic>? filter}) {
    return Uri.parse(_createEndpoint(customEndpoint)).replace(
      queryParameters: filter?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  String _createEndpoint(String customEndpoint) {
    final path = customEndpoint.isEmpty
        ? endpoint
        : '$endpoint/$customEndpoint';

    return '$baseUrl/$path';
  }

  bool _isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  Never handleHttpError(http.Response response) {
    String message = 'Server error (${response.statusCode}).';

    if (response.body.isNotEmpty) {
      try {
        final body = jsonDecode(response.body);

        if (body is Map<String, dynamic>) {
          final errors = body['errors'];

          if (errors is Map<String, dynamic>) {
            final userErrors = errors['UserError'];

            if (userErrors is List && userErrors.isNotEmpty) {
              message = userErrors.first.toString();
            }
          }

          message =
              body['message']?.toString() ??
              body['title']?.toString() ??
              message;
        }
      } catch (_) {
        message = response.body;
      }
    }

    throw CustomException(message);
  }
}
