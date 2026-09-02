import 'package:json_annotation/json_annotation.dart';

part 'order_accept.g.dart';

@JsonSerializable()
class OrderAccept {
  final DateTime shippingDate;

  const OrderAccept({required this.shippingDate});

  factory OrderAccept.fromJson(Map<String, dynamic> json) =>
      _$OrderAcceptFromJson(json);

  Map<String, dynamic> toJson() => _$OrderAcceptToJson(this);
}
