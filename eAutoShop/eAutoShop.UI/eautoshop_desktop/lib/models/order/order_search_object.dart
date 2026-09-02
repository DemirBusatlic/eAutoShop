import 'package:json_annotation/json_annotation.dart';

part 'order_search_object.g.dart';

@JsonSerializable(includeIfNull: false)
class OrderSearchObject {
  final int? page;
  final int? pageSize;
  final String? customerName;
  final String? state;
  final double? minTotalAmount;
  final double? maxTotalAmount;
  final DateTime? minOrderDate;
  final DateTime? maxOrderDate;
  final DateTime? minShippingDate;
  final DateTime? maxShippingDate;
  final bool? hasDiscount;

  const OrderSearchObject({
    this.page,
    this.pageSize,
    this.customerName,
    this.state,
    this.minTotalAmount,
    this.maxTotalAmount,
    this.minOrderDate,
    this.maxOrderDate,
    this.minShippingDate,
    this.maxShippingDate,
    this.hasDiscount,
  });

  factory OrderSearchObject.fromJson(Map<String, dynamic> json) =>
      _$OrderSearchObjectFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSearchObjectToJson(this);
}
