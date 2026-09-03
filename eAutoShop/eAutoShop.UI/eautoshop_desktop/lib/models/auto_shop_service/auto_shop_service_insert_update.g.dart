// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_shop_service_insert_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutoShopServiceInsertUpdate _$AutoShopServiceInsertUpdateFromJson(
  Map<String, dynamic> json,
) => AutoShopServiceInsertUpdate(
  serviceTypeId: (json['serviceTypeId'] as num?)?.toInt(),
  name: json['name'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  discount: (json['discount'] as num?)?.toDouble(),
  imageData: json['imageData'] as String?,
  description: json['description'] as String?,
  details: json['details'] as String?,
  duration: json['duration'] as String?,
);

Map<String, dynamic> _$AutoShopServiceInsertUpdateToJson(
  AutoShopServiceInsertUpdate instance,
) => <String, dynamic>{
  'serviceTypeId': ?instance.serviceTypeId,
  'name': ?instance.name,
  'price': ?instance.price,
  'discount': ?instance.discount,
  'imageData': ?instance.imageData,
  'description': ?instance.description,
  'details': ?instance.details,
  'duration': ?instance.duration,
};
