import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'package:eautoshop_mobile/constants.dart';
import 'notification_service.dart';

class SignalRNotificationsService {
  SignalRNotificationsService(this._notificationService);

  final NotificationService _notificationService;

  HubConnection? _connection;

  String get _hubUrl =>
      'http://${ApiHost.address}:${ApiHost.port}/notificationHub';

  Future<void> startConnection(String token) async {
    if (token.isEmpty) {
      throw ArgumentError('JWT token nije dostavljen.');
    }

    if (_connection?.state == HubConnectionState.Connected ||
        _connection?.state == HubConnectionState.Connecting) {
      return;
    }

    final connection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: HttpConnectionOptions(accessTokenFactory: () async => token),
        )
        .withAutomaticReconnect()
        .build();

    _connection = connection;

    connection.onclose(({Exception? error}) {
      if (error != null) {
        debugPrint('SignalR konekcija je prekinuta: $error');
      }
    });

    connection.on('newNotification', (arguments) async {
      await _handleNotification(arguments);
    });

    try {
      await connection.start();
      debugPrint('SignalR konekcija je uspostavljena.');
    } catch (error) {
      _connection = null;
      debugPrint('SignalR povezivanje nije uspjelo: $error');
      rethrow;
    }
  }

  Future<void> _handleNotification(List<Object?>? arguments) async {
    if (arguments == null || arguments.isEmpty) {
      return;
    }

    final rawData = arguments.first;

    if (rawData is! Map) {
      debugPrint('Primljen je nepoznat format SignalR notifikacije.');
      return;
    }

    final notificationMap = Map<String, dynamic>.from(rawData);

    final type = notificationMap['type']?.toString().toLowerCase() ?? '';

    final message = notificationMap['message']?.toString() ?? '';

    if (message.isEmpty) {
      debugPrint('SignalR notifikacija nema poruku.');
      return;
    }

    switch (type) {
      case 'newproduct':
        await _notificationService.showNotification(
          title: 'Novi proizvod',
          body: message,
          channelId: 'new_products_channel',
          channelName: 'Novi proizvodi',
        );
        break;

      case 'orderstatuschanged':
        await _notificationService.showNotification(
          title: 'Promjena statusa narudžbe',
          body: message,
          channelId: 'order_status_channel',
          channelName: 'Status narudžbi',
        );
        break;

      case 'reservationstatuschanged':
        await _notificationService.showNotification(
          title: 'Promjena statusa rezervacije',
          body: message,
          channelId: 'reservation_status_channel',
          channelName: 'Status rezervacija',
        );
        break;

      default:
        await _notificationService.showNotification(
          title: 'eAutoShop',
          body: message,
          channelId: 'general_notifications_channel',
          channelName: 'Opće obavijesti',
        );
    }
  }

  Future<void> stopConnection() async {
    final connection = _connection;

    if (connection == null) {
      return;
    }

    connection.off('newNotification');
    await connection.stop();

    _connection = null;

    debugPrint('SignalR konekcija je zaustavljena.');
  }
}
