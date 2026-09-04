import 'dart:convert';

import 'package:eautoshop_desktop/providers/base_provider.dart';
import 'package:eautoshop_desktop/services/report_notification_service.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends BaseProvider<Object?, Object?> {
  AuthProvider() : super('AuthToken');

  static const _desktopRoles = {'manager', 'salesperson', 'technician'};

  final ReportNotificationService _reportNotificationService =
      ReportNotificationService();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _currentRole;
  String? _currentUsername;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get currentRole => _currentRole;
  String? get currentUsername => _currentUsername;

  bool get isManager => _currentRole == 'manager';
  bool get isSalesperson => _currentRole == 'salesperson';
  bool get isTechnician => _currentRole == 'technician';

  ReportNotificationService get reportNotificationService =>
      _reportNotificationService;

  Future<void> initialize() async {
    final token = await storage.read(key: 'jwt_token');

    if (token == null || token.trim().isEmpty) {
      return;
    }

    try {
      final user = await _getCurrentUser();

      _applyAuthenticatedUser(user);

      await _startReportNotificationConnection(token);
    } catch (error) {
      debugPrint('Existing desktop session is not valid: $error');

      await _clearLocalSession(notify: false);
    }
  }

  Future<void> login(String username, String password) async {
    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}/AuthToken/login'),
        headers: const {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({'username': username.trim(), 'password': password}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        handleHttpError(response);
      }

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      final token = responseBody['token']?.toString();

      if (token == null || token.trim().isEmpty) {
        throw const CustomException('Server nije vratio ispravan JWT token.');
      }

      await storage.write(key: 'jwt_token', value: token);

      try {
        final user = await _getCurrentUser();

        _applyAuthenticatedUser(user);

        await _startReportNotificationConnection(token);
      } on CustomException {
        await _revokeTokenBestEffort();
        await _clearLocalSession();
        rethrow;
      } catch (error) {
        await _clearLocalSession();

        debugPrint('Loading current desktop user failed: $error');

        throw const CustomException(
          'Prijava je uspjela, ali podaci korisnika nisu učitani.',
        );
      }
    } on CustomException {
      rethrow;
    } catch (error) {
      debugPrint('Desktop login failed: $error');

      throw const CustomException(
        'Nije moguće pristupiti serveru. '
        'Provjerite da li je API pokrenut.',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _revokeTokenBestEffort();
    await _clearLocalSession();
  }

  Future<Map<String, dynamic>> _getCurrentUser() async {
    final response = await http.get(
      Uri.parse('${BaseProvider.baseUrl}/User/Me'),
      headers: await createHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      handleHttpError(response);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _applyAuthenticatedUser(Map<String, dynamic> user) {
    final role = user['roleName']?.toString().trim().toLowerCase();

    if (role == null || !_desktopRoles.contains(role)) {
      throw const CustomException(
        'Ovaj korisnički nalog nema pristup '
        'desktop aplikaciji.',
      );
    }

    _currentRole = role;
    _currentUsername = user['username']?.toString();

    _isLoggedIn = true;

    notifyListeners();
  }

  Future<void> _startReportNotificationConnection(String token) async {
    try {
      await _reportNotificationService.initConnection(token);
    } catch (error) {
      debugPrint('Report SignalR connection failed: $error');
    }
  }

  Future<void> _revokeTokenBestEffort() async {
    try {
      final token = await storage.read(key: 'jwt_token');

      if (token == null || token.trim().isEmpty) {
        return;
      }

      await http.post(
        Uri.parse('${BaseProvider.baseUrl}/AuthToken/logout'),
        headers: await createHeaders(),
      );
    } catch (error) {
      debugPrint('Server-side logout failed: $error');
    }
  }

  Future<void> _clearLocalSession({bool notify = true}) async {
    await _reportNotificationService.stopConnection();

    await storage.delete(key: 'jwt_token');

    _isLoggedIn = false;
    _currentRole = null;
    _currentUsername = null;

    if (notify) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;

    notifyListeners();
  }
}
