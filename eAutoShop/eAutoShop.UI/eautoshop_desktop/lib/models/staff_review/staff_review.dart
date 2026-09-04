import 'package:json_annotation/json_annotation.dart';

part 'staff_review.g.dart';

@JsonSerializable()
class StaffReview {
  final int id;
  final int? userId;
  final int? employeeId;
  final int? appointmentId;
  final int? rating;
  final String? comment;
  final DateTime? createdAt;
  final String? userName;
  final String? employeeName;

  const StaffReview({
    required this.id,
    this.userId,
    this.employeeId,
    this.appointmentId,
    this.rating,
    this.comment,
    this.createdAt,
    this.userName,
    this.employeeName,
  });

  factory StaffReview.fromJson(Map<String, dynamic> json) =>
      _$StaffReviewFromJson(json);

  Map<String, dynamic> toJson() => _$StaffReviewToJson(this);
}
