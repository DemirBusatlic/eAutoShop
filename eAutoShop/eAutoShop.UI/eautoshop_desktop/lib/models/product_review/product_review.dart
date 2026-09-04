import 'package:json_annotation/json_annotation.dart';

part 'product_review.g.dart';

@JsonSerializable()
class ProductReview {
  final int id;
  final int? userId;
  final int? productId;
  final int? orderItemId;
  final int? rating;
  final String? comment;
  final DateTime? createdAt;
  final String? userName;
  final String? productName;

  const ProductReview({
    required this.id,
    this.userId,
    this.productId,
    this.orderItemId,
    this.rating,
    this.comment,
    this.createdAt,
    this.userName,
    this.productName,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewFromJson(json);

  Map<String, dynamic> toJson() => _$ProductReviewToJson(this);
}
