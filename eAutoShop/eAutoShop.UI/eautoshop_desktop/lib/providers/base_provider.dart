import 'dart:convert';

import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

abstract class BaseProvider<T, TInsertUpdate> with ChangeNotifier {
  BaseProvider(this.endpoint);

  static const String baseUrl = 'http://${ApiHost.address}:${ApiHost.port}';

  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String endpoint;

  Future<Map<String, String>> createHeaders() async {
    final token = await storage.read(key: 'jwt_token');

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Future<SearchResult<T>> get({
    String customEndpoint = '',
    Map<String, dynamic>? filter,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await http.get(
        _createUri(customEndpoint: customEndpoint, filter: filter),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawResult = data['result'] as List<dynamic>? ?? const [];

        return SearchResult<T>(
          count: (data['count'] as num?)?.toInt() ?? rawResult.length,
          result: rawResult
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList(),
        );
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (error) {
      debugPrint('GET $endpoint failed: $error');
      throw const CustomException(
        'Nije moguće pristupiti serveru. Provjerite da li je API pokrenut.',
      );
    }
  }

  Future<T> getById({
    required int id,
    String customEndpoint = '',
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${_createEndpoint(customEndpoint)}/$id'),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        return fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (error) {
      debugPrint('GET $endpoint/$id failed: $error');
      throw const CustomException(
        'Nije moguće pristupiti serveru. Provjerite da li je API pokrenut.',
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
    } catch (error) {
      debugPrint('POST $endpoint failed: $error');
      throw const CustomException(
        'Nije moguće pristupiti serveru. Provjerite da li je API pokrenut.',
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
    } catch (error) {
      debugPrint('PUT $endpoint/$id failed: $error');
      throw const CustomException(
        'Nije moguće pristupiti serveru. Provjerite da li je API pokrenut.',
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
    } catch (error) {
      debugPrint('DELETE $endpoint/$id failed: $error');
      throw const CustomException(
        'Nije moguće pristupiti serveru. Provjerite da li je API pokrenut.',
      );
    }
  }

  Never handleHttpError(http.Response response) {
    var message = 'Greška servera (${response.statusCode}).';

    if (response.body.trim().isNotEmpty) {
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

  Uri _createUri({String customEndpoint = '', Map<String, dynamic>? filter}) {
    final queryParameters = <String, String>{};

    filter?.forEach((key, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        queryParameters[key] = value.toString();
      }
    });

    return Uri.parse(_createEndpoint(customEndpoint)).replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  String _createEndpoint(String customEndpoint) {
    final normalizedCustomEndpoint = customEndpoint
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .join('/');

    final path = normalizedCustomEndpoint.isEmpty
        ? endpoint
        : '$endpoint/$normalizedCustomEndpoint';

    return '$baseUrl/$path';
  }

  bool _isSuccessful(int statusCode) => statusCode >= 200 && statusCode < 300;
}
