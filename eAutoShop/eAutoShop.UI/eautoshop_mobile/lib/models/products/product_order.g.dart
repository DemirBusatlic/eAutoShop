// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductOrder _$ProductOrderFromJson(Map<String, dynamic> json) => ProductOrder(
  (json['productId'] as num).toInt(),
  (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$ProductOrderToJson(ProductOrder instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
    };
