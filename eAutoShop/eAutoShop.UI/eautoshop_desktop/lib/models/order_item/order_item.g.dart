// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: (json['id'] as num).toInt(),
  orderId: (json['orderId'] as num).toInt(),
  productId: (json['productId'] as num).toInt(),
  productName: json['productName'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unitPrice'] as num).toDouble(),
  totalItemsPrice: (json['totalItemsPrice'] as num).toDouble(),
  totalItemsPriceDiscounted: (json['totalItemsPriceDiscounted'] as num)
      .toDouble(),
  discount: (json['discount'] as num).toDouble(),
  hasProductReview: json['hasProductReview'] as bool,
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
