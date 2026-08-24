// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_review_insert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffReviewInsert _$StaffReviewInsertFromJson(Map<String, dynamic> json) =>
    StaffReviewInsert(
      employeeId: (json['employeeId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$StaffReviewInsertToJson(StaffReviewInsert instance) =>
    <String, dynamic>{
      'employeeId': instance.employeeId,
      'rating': instance.rating,
      'comment': instance.comment,
    };
