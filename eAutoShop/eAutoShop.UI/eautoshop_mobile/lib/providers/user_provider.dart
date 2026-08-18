import 'dart:convert';

import 'package:eautoshop_mobile/models/user/user.dart';
import 'package:eautoshop_mobile/models/user/user_change_password.dart';
import 'package:eautoshop_mobile/models/user/user_register.dart';
import 'package:eautoshop_mobile/models/user/user_update.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';
import 'package:eautoshop_mobile/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User, UserRegister> {
  UserProvider() : super('User');

  User? user;
  bool isLoading = false;

  Future<void> register(UserRegister request) async {
    await insert(
      request,
      customEndpoint: 'Register',
      toJson: (request) => request.toJson(),
    );
  }

  Future<void> getCurrentUser() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/Me'),
        headers: await createHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        user = User.fromJson(json);
      } else {
        handleHttpError(response);
      }
    } on CustomException {
      user = null;
      rethrow;
    } catch (_) {
      user = null;
      throw CustomException(
        "Can't reach the server. Please check your internet connection.",
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateByToken(UserUpdate request) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/UpdateByToken'),
        headers: await createHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        user = User.fromJson(json);
        notifyListeners();
      } else {
        handleHttpError(response);
      }
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check your internet connection.",
      );
    }
  }

  Future<void> changePassword(UserChangePassword request) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/ChangePassword'),
        headers: await createHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        handleHttpError(response);
      }
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check your internet connection.",
      );
    }
  }

  void clearUser() {
    user = null;
    notifyListeners();
  }
}
