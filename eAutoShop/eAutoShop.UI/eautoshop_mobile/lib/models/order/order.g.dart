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
  json['acceptedBy'] as String?,
  json['acceptedAt'] == null
      ? null
      : DateTime.parse(json['acceptedAt'] as String),
  json['rejectedBy'] as String?,
  json['rejectedAt'] == null
      ? null
      : DateTime.parse(json['rejectedAt'] as String),
  json['rejectionReason'] as String?,
  json['cancelledBy'] as String?,
  json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
  json['cancellationReason'] as String?,
  json['completedBy'] as String?,
  json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'orderDate': instance.orderDate.toIso8601String(),
  'shippingDate': instance.shippingDate?.toIso8601String(),
  'totalAmount': instance.totalAmount,
  'state': instance.state,
  'acceptedBy': instance.acceptedBy,
  'acceptedAt': instance.acceptedAt?.toIso8601String(),
  'rejectedBy': instance.rejectedBy,
  'rejectedAt': instance.rejectedAt?.toIso8601String(),
  'rejectionReason': instance.rejectionReason,
  'cancelledBy': instance.cancelledBy,
  'cancelledAt': instance.cancelledAt?.toIso8601String(),
  'cancellationReason': instance.cancellationReason,
  'completedBy': instance.completedBy,
  'completedAt': instance.completedAt?.toIso8601String(),
  'cityId': instance.cityId,
  'shippingCity': instance.shippingCity,
  'shippingAddress': instance.shippingAddress,
  'shippingPostalCode': instance.shippingPostalCode,
};
