// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_review_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffReviewUpdate _$StaffReviewUpdateFromJson(Map<String, dynamic> json) =>
    StaffReviewUpdate(
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$StaffReviewUpdateToJson(StaffReviewUpdate instance) =>
    <String, dynamic>{'rating': instance.rating, 'comment': instance.comment};
