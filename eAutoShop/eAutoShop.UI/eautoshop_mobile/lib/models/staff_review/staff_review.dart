import 'package:json_annotation/json_annotation.dart';

part 'staff_review.g.dart';

@JsonSerializable()
class StaffReview {
  int id;
  int? userId;
  int? employeeId;
  int? appointmentId;
  int? rating;
  String? comment;
  DateTime? createdAt;
  String? userName;
  String? employeeName;

  StaffReview(
    this.id,
    this.userId,
    this.employeeId,
    this.appointmentId,
    this.rating,
    this.comment,
    this.createdAt,
    this.userName,
    this.employeeName,
  );

  factory StaffReview.fromJson(Map<String, dynamic> json) =>
      _$StaffReviewFromJson(json);

  Map<String, dynamic> toJson() => _$StaffReviewToJson(this);
}
