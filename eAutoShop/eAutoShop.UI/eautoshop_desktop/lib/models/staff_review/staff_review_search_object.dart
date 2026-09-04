import 'package:json_annotation/json_annotation.dart';

part 'staff_review_search_object.g.dart';

@JsonSerializable(includeIfNull: false)
class StaffReviewSearchObject {
  final int? page;
  final int? pageSize;
  final int? rating;
  final int? userId;
  final int? employeeId;
  final String? commentFTS;

  const StaffReviewSearchObject({
    this.page,
    this.pageSize,
    this.rating,
    this.userId,
    this.employeeId,
    this.commentFTS,
  });

  factory StaffReviewSearchObject.fromJson(Map<String, dynamic> json) =>
      _$StaffReviewSearchObjectFromJson(json);

  Map<String, dynamic> toJson() => _$StaffReviewSearchObjectToJson(this);
}
