// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_review_insert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffReviewInsert _$StaffReviewInsertFromJson(Map<String, dynamic> json) =>
    StaffReviewInsert(
      appointmentId: (json['appointmentId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$StaffReviewInsertToJson(StaffReviewInsert instance) =>
    <String, dynamic>{
      'appointmentId': instance.appointmentId,
      'rating': instance.rating,
      'comment': instance.comment,
    };
