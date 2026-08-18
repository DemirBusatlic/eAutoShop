import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  int id;
  String username;
  DateTime orderDate;
  DateTime? shippingDate;
  double totalAmount;
  String state;
  int cityId;
  String shippingCity;
  String shippingAddress;
  String shippingPostalCode;

  Order(
    this.id,
    this.username,
    this.orderDate,
    this.shippingDate,
    this.totalAmount,
    this.state,
    this.cityId,
    this.shippingCity,
    this.shippingAddress,
    this.shippingPostalCode,
  );

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
