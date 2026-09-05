// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_review_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductReviewUpdate _$ProductReviewUpdateFromJson(Map<String, dynamic> json) =>
    ProductReviewUpdate(
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$ProductReviewUpdateToJson(
  ProductReviewUpdate instance,
) => <String, dynamic>{'rating': instance.rating, 'comment': instance.comment};
