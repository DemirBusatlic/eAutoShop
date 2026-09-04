import 'package:json_annotation/json_annotation.dart';

part 'product_review_search_object.g.dart';

@JsonSerializable(includeIfNull: false)
class ProductReviewSearchObject {
  final int? page;
  final int? pageSize;
  final int? rating;
  final int? userId;
  final int? productId;
  final String? commentFTS;

  const ProductReviewSearchObject({
    this.page,
    this.pageSize,
    this.rating,
    this.userId,
    this.productId,
    this.commentFTS,
  });

  factory ProductReviewSearchObject.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewSearchObjectFromJson(json);

  Map<String, dynamic> toJson() => _$ProductReviewSearchObjectToJson(this);
}
