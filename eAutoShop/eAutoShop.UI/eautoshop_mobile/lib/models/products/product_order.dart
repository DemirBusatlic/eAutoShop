import 'package:json_annotation/json_annotation.dart';

part 'product_order.g.dart';

@JsonSerializable()
class ProductOrder {
  int productId;
  int quantity;

  ProductOrder(this.productId, this.quantity);

  factory ProductOrder.fromJson(Map<String, dynamic> json) =>
      _$ProductOrderFromJson(json);

  Map<String, dynamic> toJson() => _$ProductOrderToJson(this);
}
