// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_review_insert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductReviewInsert _$ProductReviewInsertFromJson(Map<String, dynamic> json) =>
    ProductReviewInsert(
      (json['productId'] as num).toInt(),
      (json['rating'] as num).toInt(),
      json['comment'] as String?,
    );

Map<String, dynamic> _$ProductReviewInsertToJson(
  ProductReviewInsert instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'rating': instance.rating,
  'comment': instance.comment,
};
