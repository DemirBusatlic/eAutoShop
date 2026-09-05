import 'dart:convert';

import 'package:eautoshop_mobile/models/staff_review/staff_review.dart';
import 'package:eautoshop_mobile/models/staff_review/staff_review_insert.dart';
import 'package:eautoshop_mobile/models/staff_review/staff_review_update.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';
import 'package:eautoshop_mobile/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class StaffReviewProvider extends BaseProvider<StaffReview, StaffReviewInsert> {
  bool isSubmitting = false;

  StaffReviewProvider() : super('StaffReview');

  Future<void> addReview(StaffReviewInsert review) async {
    isSubmitting = true;
    notifyListeners();

    try {
      await insert(review, toJson: (value) => value.toJson());
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<StaffReview?> getByAppointment(int appointmentId) async {
    final result = await get(
      filter: {'AppointmentId': appointmentId, 'PageSize': 1},
      fromJson: StaffReview.fromJson,
    );

    if (result.result.isEmpty) {
      return null;
    }

    return result.result.first;
  }

  Future<void> updateReview(int id, StaffReviewUpdate review) async {
    isSubmitting = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/$id'),
        headers: await createHeaders(),
        body: jsonEncode(review.toJson()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        handleHttpError(response);
      }
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException(
        "Can't reach the server. Please check whether the API is running.",
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteReview(int id) async {
    isSubmitting = true;
    notifyListeners();

    try {
      await delete(id);
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
