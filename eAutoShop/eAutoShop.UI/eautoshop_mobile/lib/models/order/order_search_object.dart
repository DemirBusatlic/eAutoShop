import 'package:json_annotation/json_annotation.dart';

part 'order_search_object.g.dart';

@JsonSerializable(includeIfNull: false)
class OrderSearchObject {
  int? page;
  int? pageSize;
  String? customerName;
  String? state;
  double? minTotalAmount;
  double? maxTotalAmount;
  DateTime? minOrderDate;
  DateTime? maxOrderDate;
  DateTime? minShippingDate;
  DateTime? maxShippingDate;
  bool? hasDiscount;
  bool? includeItems;

  OrderSearchObject({
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
    this.includeItems,
  });

  factory OrderSearchObject.fromJson(Map<String, dynamic> json) =>
      _$OrderSearchObjectFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSearchObjectToJson(this);
}
