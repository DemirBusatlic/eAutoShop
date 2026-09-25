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
  acceptedBy: json['acceptedBy'] as String?,
  acceptedAt: json['acceptedAt'] == null
      ? null
      : DateTime.parse(json['acceptedAt'] as String),
  rejectedBy: json['rejectedBy'] as String?,
  rejectedAt: json['rejectedAt'] == null
      ? null
      : DateTime.parse(json['rejectedAt'] as String),
  rejectionReason: json['rejectionReason'] as String?,
  cancelledBy: json['cancelledBy'] as String?,
  cancelledAt: json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
  cancellationReason: json['cancellationReason'] as String?,
  completedBy: json['completedBy'] as String?,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
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
