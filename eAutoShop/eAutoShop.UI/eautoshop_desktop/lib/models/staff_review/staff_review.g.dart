// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffReview _$StaffReviewFromJson(Map<String, dynamic> json) => StaffReview(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  employeeId: (json['employeeId'] as num?)?.toInt(),
  appointmentId: (json['appointmentId'] as num?)?.toInt(),
  rating: (json['rating'] as num?)?.toInt(),
  comment: json['comment'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  userName: json['userName'] as String?,
  employeeName: json['employeeName'] as String?,
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
