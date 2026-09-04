// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_review_search_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffReviewSearchObject _$StaffReviewSearchObjectFromJson(
  Map<String, dynamic> json,
) => StaffReviewSearchObject(
  page: (json['page'] as num?)?.toInt(),
  pageSize: (json['pageSize'] as num?)?.toInt(),
  rating: (json['rating'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  employeeId: (json['employeeId'] as num?)?.toInt(),
  commentFTS: json['commentFTS'] as String?,
);

Map<String, dynamic> _$StaffReviewSearchObjectToJson(
  StaffReviewSearchObject instance,
) => <String, dynamic>{
  'page': ?instance.page,
  'pageSize': ?instance.pageSize,
  'rating': ?instance.rating,
  'userId': ?instance.userId,
  'employeeId': ?instance.employeeId,
  'commentFTS': ?instance.commentFTS,
};
