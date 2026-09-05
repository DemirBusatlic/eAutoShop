import 'package:json_annotation/json_annotation.dart';

part 'product_review_update.g.dart';

@JsonSerializable()
class ProductReviewUpdate {
  int rating;
  String? comment;

  ProductReviewUpdate({required this.rating, this.comment});

  factory ProductReviewUpdate.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ProductReviewUpdateToJson(this);
}
