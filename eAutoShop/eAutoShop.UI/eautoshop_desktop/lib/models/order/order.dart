import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final int id;
  final String username;
  final DateTime orderDate;
  final DateTime? shippingDate;
  final double totalAmount;
  final String state;
  final int cityId;
  final String shippingCity;
  final String shippingAddress;
  final String shippingPostalCode;

  const Order({
    required this.id,
    required this.username,
    required this.orderDate,
    required this.totalAmount,
    required this.state,
    required this.cityId,
    required this.shippingCity,
    required this.shippingAddress,
    required this.shippingPostalCode,
    this.shippingDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
