// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  (json['id'] as num).toInt(),
  (json['orderId'] as num).toInt(),
  (json['productId'] as num).toInt(),
  json['productName'] as String,
  (json['quantity'] as num).toInt(),
  (json['unitPrice'] as num).toDouble(),
  (json['totalItemsPrice'] as num).toDouble(),
  (json['totalItemsPriceDiscounted'] as num).toDouble(),
  (json['discount'] as num).toDouble(),
  json['hasProductReview'] as bool? ?? false,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'productId': instance.productId,
  'productName': instance.productName,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'totalItemsPrice': instance.totalItemsPrice,
  'totalItemsPriceDiscounted': instance.totalItemsPriceDiscounted,
  'discount': instance.discount,
  'hasProductReview': instance.hasProductReview,
};
