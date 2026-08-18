import 'package:json_annotation/json_annotation.dart';

part 'product_review_insert.g.dart';

@JsonSerializable()
class ProductReviewInsert {
  int productId;
  int rating;
  String? comment;

  ProductReviewInsert(this.productId, this.rating, this.comment);

  factory ProductReviewInsert.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewInsertFromJson(json);

  Map<String, dynamic> toJson() => _$ProductReviewInsertToJson(this);
}
