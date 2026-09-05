import 'package:json_annotation/json_annotation.dart';

part 'product_review.g.dart';

@JsonSerializable()
class ProductReview {
  int id;
  int? userId;
  int? productId;
  int? orderItemId;
  int? rating;
  String? comment;
  DateTime? createdAt;
  String? userName;
  String? productName;

  ProductReview(
    this.id,
    this.userId,
    this.productId,
    this.orderItemId,
    this.rating,
    this.comment,
    this.createdAt,
    this.userName,
    this.productName,
  );

  factory ProductReview.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewFromJson(json);

  Map<String, dynamic> toJson() => _$ProductReviewToJson(this);
}
