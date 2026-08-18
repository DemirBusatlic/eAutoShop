import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:eautoshop_mobile/providers/base_provider.dart';
import 'package:eautoshop_mobile/services/signalr_notifications_service.dart';
import 'package:eautoshop_mobile/utilities/custom_exception.dart';

class AuthProvider extends BaseProvider<AuthProvider, AuthProvider> {
  AuthProvider(this._signalRService) : super('Auth');

  final SignalRNotificationsService _signalRService;

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void _setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}/AuthToken/login'),
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': 'customer',
        }),
      );

      if (response.statusCode != 200) {
        handleHttpError(response);
      }

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      final token = responseBody['token']?.toString();

      if (token == null || token.isEmpty) {
        throw CustomException('Server nije vratio ispravan JWT token.');
      }

      await storage.write(key: 'jwt_token', value: token);

      _setLoggedIn(true);

      // Greška SignalR-a ne treba poništiti uspješnu prijavu.
      try {
        await _signalRService.startConnection(token);
      } catch (error) {
        debugPrint(
          'Prijava je uspješna, ali SignalR povezivanje nije uspjelo: $error',
        );
      }
    } on CustomException {
      rethrow;
    } catch (error) {
      debugPrint('Greška prilikom prijave: $error');

      throw CustomException(
        "Can't reach the server. Please check your internet connection.",
      );
    }
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}/AuthToken/logout'),
        headers: await createHeaders(),
      );

      if (response.statusCode != 200) {
        handleHttpError(response);
      }

      await _clearLocalSession();
    } on CustomException {
      rethrow;
    } catch (error) {
      debugPrint('Greška prilikom odjave: $error');

      throw CustomException(
        "Can't reach the server. Please check your internet connection.",
      );
    }
  }

  Future<void> clearSession() async {
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    await _signalRService.stopConnection();

    // Bolje je izbrisati token nego sačuvati prazan string.
    await storage.delete(key: 'jwt_token');

    _setLoggedIn(false);
  }
}
