import 'package:eautoshop_mobile/models/products/product_order.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_insert.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderInsert {
  bool userAddress;
  int? cityId;
  String? shippingAddress;
  String? shippingPostalCode;

  @JsonKey(name: 'product')
  List<ProductOrder> products;

  OrderInsert({
    required this.userAddress,
    this.cityId,
    this.shippingAddress,
    this.shippingPostalCode,
    required this.products,
  });

  factory OrderInsert.fromJson(Map<String, dynamic> json) =>
      _$OrderInsertFromJson(json);

  Map<String, dynamic> toJson() => _$OrderInsertToJson(this);
}
