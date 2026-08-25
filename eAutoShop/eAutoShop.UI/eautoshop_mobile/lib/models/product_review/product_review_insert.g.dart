// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_review_insert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductReviewInsert _$ProductReviewInsertFromJson(Map<String, dynamic> json) =>
    ProductReviewInsert(
      (json['orderItemId'] as num).toInt(),
      (json['rating'] as num).toInt(),
      json['comment'] as String?,
    );

Map<String, dynamic> _$ProductReviewInsertToJson(
  ProductReviewInsert instance,
) => <String, dynamic>{
  'orderItemId': instance.orderItemId,
  'rating': instance.rating,
  'comment': instance.comment,
};
