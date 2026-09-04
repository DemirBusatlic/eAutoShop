import 'package:signalr_netcore/signalr_client.dart';

import 'package:eautoshop_desktop/constants.dart';

class ReportNotificationService {
  HubConnection? _connection;
  bool _initialized = false;

  String get _baseUrl =>
      'http://${ApiHost.address}:${ApiHost.port}/reportNotificationHub';

  Function(String notificationType, String message)? onNotificationReceived;

  bool get isInitialized => _initialized;

  Future<void> initConnection(String token) async {
    if (_initialized && _connection?.state == HubConnectionState.Connected) {
      return;
    }

    _connection = HubConnectionBuilder()
        .withUrl(
          _baseUrl,
          options: HttpConnectionOptions(accessTokenFactory: () async => token),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReportNotification', _onReportNotification);

    await _connection!.start();

    _initialized = _connection!.state == HubConnectionState.Connected;
  }

  void _onReportNotification(List<Object?>? arguments) {
    if (arguments == null || arguments.length < 2) {
      return;
    }

    final notificationType = arguments[0]?.toString() ?? '';

    final message = arguments[1]?.toString() ?? '';

    if (notificationType.isEmpty) {
      return;
    }

    onNotificationReceived?.call(notificationType, message);
  }

  Future<void> stopConnection() async {
    if (_connection != null &&
        _connection!.state == HubConnectionState.Connected) {
      await _connection!.stop();
    }

    _initialized = false;
  }
}
