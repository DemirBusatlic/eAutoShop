import 'package:json_annotation/json_annotation.dart';

part 'product_review_insert.g.dart';

@JsonSerializable()
class ProductReviewInsert {
  int orderItemId;
  int rating;
  String? comment;

  ProductReviewInsert(this.orderItemId, this.rating, this.comment);

  factory ProductReviewInsert.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewInsertFromJson(json);

  Map<String, dynamic> toJson() => _$ProductReviewInsertToJson(this);
}
