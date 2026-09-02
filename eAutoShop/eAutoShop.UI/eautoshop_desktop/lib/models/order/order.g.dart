// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  orderDate: DateTime.parse(json['orderDate'] as String),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  state: json['state'] as String,
  cityId: (json['cityId'] as num).toInt(),
  shippingCity: json['shippingCity'] as String,
  shippingAddress: json['shippingAddress'] as String,
  shippingPostalCode: json['shippingPostalCode'] as String,
  shippingDate: json['shippingDate'] == null
      ? null
      : DateTime.parse(json['shippingDate'] as String),
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
