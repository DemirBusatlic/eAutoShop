import 'dart:convert';

import 'package:eautoshop_desktop/models/user/user.dart';
import 'package:eautoshop_desktop/models/user/user_change_password.dart';
import 'package:eautoshop_desktop/models/user/user_insert.dart';
import 'package:eautoshop_desktop/models/user/user_update.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User, UserInsert> {
  UserProvider() : super('User');

  List<User> customers = [];
  List<User> employees = [];
  User? currentUser;

  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getCustomers({String? containsUsername, bool? active}) async {
    isLoading = true;
    notifyListeners();

    try {
      final searchResult = await get(
        filter: {
          'Role': 'customer',
          'ContainsUsername': containsUsername,
          'Active': active,
        },
        fromJson: User.fromJson,
      );

      customers = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      customers = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getEmployees({String? containsUsername, bool? active}) async {
    isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        get(
          filter: {
            'Role': 'salesperson',
            'ContainsUsername': containsUsername,
            'Active': active,
          },
          fromJson: User.fromJson,
        ),
        get(
          filter: {
            'Role': 'technician',
            'ContainsUsername': containsUsername,
            'Active': active,
          },
          fromJson: User.fromJson,
        ),
      ]);

      employees = [...results[0].result, ...results[1].result];

      employees.sort((first, second) {
        final firstName = '${first.name ?? ''} ${first.surname ?? ''}'
            .trim()
            .toLowerCase();
        final secondName = '${second.name ?? ''} ${second.surname ?? ''}'
            .trim()
            .toLowerCase();

        return firstName.compareTo(secondName);
      });

      countOfItems = results[0].count + results[1].count;
    } catch (_) {
      employees = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> insertUser(UserInsert request) async {
    await insert(request, toJson: (item) => item.toJson());
  }

  Future<void> updateUser({
    required int id,
    required UserUpdate request,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/$id'),
        headers: await createHeaders(),
        body: jsonEncode(request.toJson()),
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

  Future<void> getCurrentUser() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/Me'),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        currentUser = User.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        return;
      }

      handleHttpError(response);
    } on CustomException {
      currentUser = null;
      rethrow;
    } catch (_) {
      currentUser = null;
      throw const CustomException(
        'Nije moguće pristupiti serveru. '
        'Provjerite da li je API pokrenut.',
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

      if (_isSuccessful(response.statusCode)) {
        currentUser = User.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
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

  Future<void> changePassword(UserChangePassword request) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/ChangePassword'),
        headers: await createHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (_isSuccessful(response.statusCode)) {
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

  Future<void> changeActiveStatus(int id) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${BaseProvider.baseUrl}/'
          '$endpoint/ChangeActiveStatus/$id',
        ),
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

  void clearCurrentUser() {
    currentUser = null;
    notifyListeners();
  }

  bool _isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
