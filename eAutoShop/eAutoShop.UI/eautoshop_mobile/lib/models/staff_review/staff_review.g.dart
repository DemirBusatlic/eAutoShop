// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffReview _$StaffReviewFromJson(Map<String, dynamic> json) => StaffReview(
  (json['id'] as num).toInt(),
  (json['userId'] as num?)?.toInt(),
  (json['employeeId'] as num?)?.toInt(),
  (json['appointmentId'] as num?)?.toInt(),
  (json['rating'] as num?)?.toInt(),
  json['comment'] as String?,
  json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  json['userName'] as String?,
  json['employeeName'] as String?,
);

Map<String, dynamic> _$StaffReviewToJson(StaffReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'employeeId': instance.employeeId,
      'appointmentId': instance.appointmentId,
      'rating': instance.rating,
      'comment': instance.comment,
      'createdAt': instance.createdAt?.toIso8601String(),
      'userName': instance.userName,
      'employeeName': instance.employeeName,
    };
