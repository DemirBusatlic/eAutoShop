import 'dart:convert';

import 'package:eautoshop_mobile/models/app_notification.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';
import 'package:eautoshop_mobile/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class NotificationProvider extends BaseProvider<AppNotification, Object> {
  NotificationProvider() : super('Notification');

  List<AppNotification> notifications = [];
  bool isLoading = false;

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  Future<void> fetchNotifications() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint'),
        headers: await createHeaders(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        handleHttpError(response);
      }

      final data = jsonDecode(response.body) as List<dynamic>;

      notifications = data
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException('Nije moguće učitati notifikacije.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/MarkAsRead/$id'),
        headers: await createHeaders(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        handleHttpError(response);
      }

      final updated = AppNotification.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      final index = notifications.indexWhere(
        (notification) => notification.id == updated.id,
      );

      if (index != -1) {
        notifications[index] = updated;
        notifyListeners();
      }
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException('Nije moguće označiti notifikaciju kao pročitanu.');
    }
  }

  void clear() {
    notifications = [];
    isLoading = false;
    notifyListeners();
  }
}
