// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  (json['id'] as num).toInt(),
  json['username'] as String,
  DateTime.parse(json['orderDate'] as String),
  json['shippingDate'] == null
      ? null
      : DateTime.parse(json['shippingDate'] as String),
  (json['totalAmount'] as num).toDouble(),
  json['state'] as String,
  (json['cityId'] as num).toInt(),
  json['shippingCity'] as String,
  json['shippingAddress'] as String,
  json['shippingPostalCode'] as String,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'orderDate': instance.orderDate.toIso8601String(),
  'shippingDate': instance.shippingDate?.toIso8601String(),
  'totalAmount': instance.totalAmount,
  'state': instance.state,
  'cityId': instance.cityId,
  'shippingCity': instance.shippingCity,
  'shippingAddress': instance.shippingAddress,
  'shippingPostalCode': instance.shippingPostalCode,
};
