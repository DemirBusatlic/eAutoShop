// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_shop_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutoShopService _$AutoShopServiceFromJson(Map<String, dynamic> json) =>
    AutoShopService(
      id: (json['id'] as num).toInt(),
      serviceTypeId: (json['serviceTypeId'] as num).toInt(),
      serviceTypeName: json['serviceTypeName'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      discountedPrice: (json['discountedPrice'] as num).toDouble(),
      state: json['state'] as String,
      imageData: json['imageData'] as String?,
      description: json['description'] as String,
      details: json['details'] as String?,
      duration: json['duration'] as String,
    );

Map<String, dynamic> _$AutoShopServiceToJson(AutoShopService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceTypeId': instance.serviceTypeId,
      'serviceTypeName': instance.serviceTypeName,
      'name': instance.name,
      'price': instance.price,
      'discount': instance.discount,
      'discountedPrice': instance.discountedPrice,
      'state': instance.state,
      'imageData': instance.imageData,
      'description': instance.description,
      'details': instance.details,
      'duration': instance.duration,
    };
