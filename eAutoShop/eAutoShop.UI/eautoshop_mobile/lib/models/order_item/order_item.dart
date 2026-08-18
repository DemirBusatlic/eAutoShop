import 'package:json_annotation/json_annotation.dart';

part 'order_item.g.dart';

@JsonSerializable()
class OrderItem {
  int id;
  int orderId;
  int productId;
  String productName;
  int quantity;
  double unitPrice;
  double totalItemsPrice;
  double totalItemsPriceDiscounted;
  double discount;

  OrderItem(
    this.id,
    this.orderId,
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.totalItemsPrice,
    this.totalItemsPriceDiscounted,
    this.discount,
  );

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}
