// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_search_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderSearchObject _$OrderSearchObjectFromJson(Map<String, dynamic> json) =>
    OrderSearchObject(
      page: (json['page'] as num?)?.toInt(),
      pageSize: (json['pageSize'] as num?)?.toInt(),
      customerName: json['customerName'] as String?,
      state: json['state'] as String?,
      minTotalAmount: (json['minTotalAmount'] as num?)?.toDouble(),
      maxTotalAmount: (json['maxTotalAmount'] as num?)?.toDouble(),
      minOrderDate: json['minOrderDate'] == null
          ? null
          : DateTime.parse(json['minOrderDate'] as String),
      maxOrderDate: json['maxOrderDate'] == null
          ? null
          : DateTime.parse(json['maxOrderDate'] as String),
      minShippingDate: json['minShippingDate'] == null
          ? null
          : DateTime.parse(json['minShippingDate'] as String),
      maxShippingDate: json['maxShippingDate'] == null
          ? null
          : DateTime.parse(json['maxShippingDate'] as String),
      hasDiscount: json['hasDiscount'] as bool?,
    );

Map<String, dynamic> _$OrderSearchObjectToJson(OrderSearchObject instance) =>
    <String, dynamic>{
      'page': ?instance.page,
      'pageSize': ?instance.pageSize,
      'customerName': ?instance.customerName,
      'state': ?instance.state,
      'minTotalAmount': ?instance.minTotalAmount,
      'maxTotalAmount': ?instance.maxTotalAmount,
      'minOrderDate': ?instance.minOrderDate?.toIso8601String(),
      'maxOrderDate': ?instance.maxOrderDate?.toIso8601String(),
      'minShippingDate': ?instance.minShippingDate?.toIso8601String(),
      'maxShippingDate': ?instance.maxShippingDate?.toIso8601String(),
      'hasDiscount': ?instance.hasDiscount,
    };
