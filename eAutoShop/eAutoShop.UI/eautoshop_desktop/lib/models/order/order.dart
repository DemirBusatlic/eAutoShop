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
  final String? acceptedBy;
  final DateTime? acceptedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? completedBy;
  final DateTime? completedAt;
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
    this.acceptedBy,
    this.acceptedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationReason,
    this.completedBy,
    this.completedAt,
    required this.cityId,
    required this.shippingCity,
    required this.shippingAddress,
    required this.shippingPostalCode,
    this.shippingDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
