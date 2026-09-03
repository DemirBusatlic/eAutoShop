import 'dart:convert';

import 'package:eautoshop_desktop/models/appointment/appointment.dart';
import 'package:eautoshop_desktop/models/appointment/appointment_confirm.dart';
import 'package:eautoshop_desktop/models/appointment/appointment_search_object.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class AppointmentProvider
    extends BaseProvider<Appointment, AppointmentConfirm> {
  AppointmentProvider() : super('Appointment');

  List<Appointment> appointments = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getAppointments({
    required bool isManager,
    required int page,
    required int pageSize,
    AppointmentSearchObject? search,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final queryParameters = <String, dynamic>{
        if (search != null) ...search.toJson(),
        'Page': page,
        'PageSize': pageSize,
      };

      final SearchResult<Appointment> searchResult = await get(
        customEndpoint: isManager ? 'GetByShop' : 'GetByEmployee',
        filter: queryParameters,
        fromJson: Appointment.fromJson,
      );

      appointments = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      appointments = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Appointment> confirmAppointment({
    required int id,
    required AppointmentConfirm request,
  }) async {
    return _putAppointment(path: 'Confirm/$id', body: request.toJson());
  }

  Future<Appointment> rejectAppointment({
    required int id,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();

    if (trimmedReason.isEmpty) {
      throw const CustomException('Unesite razlog odbijanja rezervacije.');
    }

    return _putAppointment(
      path: 'Reject/$id/${Uri.encodeComponent(trimmedReason)}',
    );
  }

  Future<Appointment> startAppointment(int id) async {
    return _putAppointment(path: 'Start/$id');
  }

  Future<Appointment> updateEstimatedCompletion({
    required int id,
    required DateTime estimatedCompletion,
  }) async {
    final encodedDate = Uri.encodeComponent(
      estimatedCompletion.toUtc().toIso8601String(),
    );

    return _putAppointment(path: 'UpdateEstimatedDate/$id/$encodedDate');
  }

  Future<Appointment> completeAppointment(int id) async {
    return _putAppointment(path: 'Complete/$id');
  }

  Future<Appointment> softDeleteAppointment(int id) async {
    return _putAppointment(path: 'SoftDelete/$id');
  }

  Future<List<String>> getAllowedActions(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/AllowedActions/$id'),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        final data = jsonDecode(response.body) as List<dynamic>;

        return data.map((action) => action.toString()).toList();
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

  Future<Appointment> _putAppointment({
    required String path,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/$path'),
        headers: await createHeaders(),
        body: body == null ? null : jsonEncode(body),
      );

      if (_isSuccessful(response.statusCode)) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final appointment = Appointment.fromJson(data);

        notifyListeners();
        return appointment;
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

  bool _isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
