import 'package:json_annotation/json_annotation.dart';

part 'staff_review_update.g.dart';

@JsonSerializable()
class StaffReviewUpdate {
  int rating;
  String? comment;

  StaffReviewUpdate({required this.rating, this.comment});

  factory StaffReviewUpdate.fromJson(Map<String, dynamic> json) =>
      _$StaffReviewUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$StaffReviewUpdateToJson(this);
}
