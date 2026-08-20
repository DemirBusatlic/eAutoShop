import 'dart:convert';

import 'package:eautoshop_mobile/models/appointment/appointment.dart';
import 'package:eautoshop_mobile/models/appointment/appointment_insert.dart';
import 'package:eautoshop_mobile/models/appointment/appointment_search_object.dart';
import 'package:eautoshop_mobile/models/appointment/appointment_update.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';
import 'package:eautoshop_mobile/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class AppointmentProvider extends BaseProvider<Appointment, AppointmentInsert> {
  List<Appointment> appointments = [];
  int countOfItems = 0;
  bool isLoading = false;

  AppointmentProvider() : super('Appointment');

  Future<void> getByCustomer({
    required int pageNumber,
    required int pageSize,
    AppointmentSearchObject? appointmentSearch,
  }) async {
    isLoading = true;
    notifyListeners();

    final Map<String, dynamic> queryParams = {
      if (appointmentSearch != null) ...appointmentSearch.toJson(),
      'Page': pageNumber,
      'PageSize': pageSize,
    };

    queryParams.removeWhere((key, value) {
      return value == null || (value is String && value.trim().isEmpty);
    });

    try {
      final SearchResult<Appointment> searchResult = await get(
        customEndpoint: 'GetByCustomer',
        filter: queryParams,
        fromJson: (json) => Appointment.fromJson(json),
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

  Future<Appointment> insertAppointment(AppointmentInsert appointment) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint'),
        headers: await createHeaders(),
        body: jsonEncode(appointment.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final createdAppointment = Appointment.fromJson(data);
        notifyListeners();

        return createdAppointment;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<Appointment> updateAppointment({
    required int id,
    required AppointmentUpdate appointment,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/$id'),
        headers: await createHeaders(),
        body: jsonEncode(appointment.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final updatedAppointment = Appointment.fromJson(data);
        notifyListeners();

        return updatedAppointment;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<Appointment> cancel({required int id, required String reason}) async {
    if (reason.trim().isEmpty) {
      throw CustomException('Cancellation reason is required.');
    }

    try {
      final encodedReason = Uri.encodeComponent(reason.trim());

      final response = await http.put(
        Uri.parse(
          '${BaseProvider.baseUrl}/$endpoint/Cancel/$id/$encodedReason',
        ),
        headers: await createHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final cancelledAppointment = Appointment.fromJson(data);
        notifyListeners();

        return cancelledAppointment;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }

  Future<Appointment> softDelete(int id) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/SoftDelete/$id'),
        headers: await createHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final deletedAppointment = Appointment.fromJson(data);
        notifyListeners();

        return deletedAppointment;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    }
  }
}
