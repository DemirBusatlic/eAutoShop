// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_review_search_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductReviewSearchObject _$ProductReviewSearchObjectFromJson(
  Map<String, dynamic> json,
) => ProductReviewSearchObject(
  page: (json['page'] as num?)?.toInt(),
  pageSize: (json['pageSize'] as num?)?.toInt(),
  rating: (json['rating'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  productId: (json['productId'] as num?)?.toInt(),
  commentFTS: json['commentFTS'] as String?,
);

Map<String, dynamic> _$ProductReviewSearchObjectToJson(
  ProductReviewSearchObject instance,
) => <String, dynamic>{
  'page': ?instance.page,
  'pageSize': ?instance.pageSize,
  'rating': ?instance.rating,
  'userId': ?instance.userId,
  'productId': ?instance.productId,
  'commentFTS': ?instance.commentFTS,
};
