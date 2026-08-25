import 'package:json_annotation/json_annotation.dart';

part 'staff_review_insert.g.dart';

@JsonSerializable()
class StaffReviewInsert {
  int appointmentId;
  int rating;
  String? comment;

  StaffReviewInsert({
    required this.appointmentId,
    required this.rating,
    this.comment,
  });

  factory StaffReviewInsert.fromJson(Map<String, dynamic> json) =>
      _$StaffReviewInsertFromJson(json);

  Map<String, dynamic> toJson() => _$StaffReviewInsertToJson(this);
}
