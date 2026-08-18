// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_insert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderInsert _$OrderInsertFromJson(Map<String, dynamic> json) => OrderInsert(
  userAddress: json['userAddress'] as bool,
  cityId: (json['cityId'] as num?)?.toInt(),
  shippingAddress: json['shippingAddress'] as String?,
  shippingPostalCode: json['shippingPostalCode'] as String?,
  products: (json['product'] as List<dynamic>)
      .map((e) => ProductOrder.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OrderInsertToJson(OrderInsert instance) =>
    <String, dynamic>{
      'userAddress': instance.userAddress,
      'cityId': instance.cityId,
      'shippingAddress': instance.shippingAddress,
      'shippingPostalCode': instance.shippingPostalCode,
      'product': instance.products.map((e) => e.toJson()).toList(),
    };
