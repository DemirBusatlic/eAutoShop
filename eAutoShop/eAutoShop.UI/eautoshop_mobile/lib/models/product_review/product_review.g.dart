// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductReview _$ProductReviewFromJson(Map<String, dynamic> json) =>
    ProductReview(
      (json['id'] as num).toInt(),
      (json['userId'] as num?)?.toInt(),
      (json['productId'] as num?)?.toInt(),
      (json['orderItemId'] as num?)?.toInt(),
      (json['rating'] as num?)?.toInt(),
      json['comment'] as String?,
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      json['userName'] as String?,
      json['productName'] as String?,
    );

Map<String, dynamic> _$ProductReviewToJson(ProductReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'productId': instance.productId,
      'orderItemId': instance.orderItemId,
      'rating': instance.rating,
      'comment': instance.comment,
      'createdAt': instance.createdAt?.toIso8601String(),
      'userName': instance.userName,
      'productName': instance.productName,
    };
