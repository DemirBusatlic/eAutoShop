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
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  void _setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  Future<void> initializeSession() async {
    if (_isInitialized) {
      return;
    }

    try {
      final token = await storage.read(key: 'jwt_token');

      if (token == null || token.trim().isEmpty) {
        await storage.delete(key: 'jwt_token');
        _isLoggedIn = false;
        return;
      }

      final currentUser = await _getCurrentUser(token);

      final roleName = currentUser['roleName']?.toString().trim().toLowerCase();

      if (roleName != 'customer') {
        debugPrint('Sačuvana mobilna sesija ne pripada customer korisniku.');

        await _clearLocalSession();
        return;
      }

      _isLoggedIn = true;

      try {
        await _signalRService.startConnection(token);
      } catch (error) {
        debugPrint(
          'Sesija je obnovljena, ali SignalR povezivanje nije uspjelo: $error',
        );
      }
    } catch (error) {
      debugPrint('Sačuvana sesija nije validna: $error');
      await _clearLocalSession();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    String? token;

    try {
      final response = await http
          .post(
            Uri.parse('${BaseProvider.baseUrl}/AuthToken/login'),
            headers: const {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        handleHttpError(response);
      }

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      token = responseBody['token']?.toString();

      if (token == null || token.trim().isEmpty) {
        throw CustomException('Server nije vratio ispravan JWT token.');
      }

      await storage.write(key: 'jwt_token', value: token);

      try {
        final currentUser = await _getCurrentUser(token);

        final roleName = currentUser['roleName']
            ?.toString()
            .trim()
            .toLowerCase();

        if (roleName != 'customer') {
          throw CustomException('Mobilna aplikacija je dostupna samo kupcima.');
        }
      } catch (_) {
        await _clearLocalSession();
        rethrow;
      }

      _setLoggedIn(true);

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
      if (token != null) {
        await _clearLocalSession();
      }

      debugPrint('Greška prilikom prijave: $error');

      throw CustomException(
        "Can't reach the server. Please check your internet connection.",
      );
    }
  }

  Future<void> logout() async {
    try {
      final response = await http
          .post(
            Uri.parse('${BaseProvider.baseUrl}/AuthToken/logout'),
            headers: await createHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Server-side logout nije uspio. '
          'Status: ${response.statusCode}.',
        );
      }
    } catch (error) {
      debugPrint(
        'Server nije dostupan tokom odjave. '
        'Lokalna sesija će ipak biti obrisana: $error',
      );
    } finally {
      await _clearLocalSession();
    }
  }

  Future<void> clearSession() async {
    await _clearLocalSession();
  }

  Future<Map<String, dynamic>> _getCurrentUser(String token) async {
    final response = await http
        .get(
          Uri.parse('${BaseProvider.baseUrl}/User/Me'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      handleHttpError(response);
    }

    final responseBody = jsonDecode(response.body);

    if (responseBody is! Map<String, dynamic>) {
      throw CustomException('Server nije vratio ispravne podatke o korisniku.');
    }

    return responseBody;
  }

  Future<void> _clearLocalSession() async {
    try {
      await _signalRService.stopConnection();
    } catch (error) {
      debugPrint('SignalR konekcija nije pravilno zaustavljena: $error');
    }

    try {
      await storage.delete(key: 'jwt_token');
    } finally {
      _setLoggedIn(false);
    }
  }
}
