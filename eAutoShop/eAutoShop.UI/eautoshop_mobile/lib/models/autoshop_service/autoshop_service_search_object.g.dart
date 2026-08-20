// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'autoshop_service_search_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutoShopServiceSearchObject _$AutoShopServiceSearchObjectFromJson(
  Map<String, dynamic> json,
) => AutoShopServiceSearchObject(
  serviceType: json['serviceType'] as String?,
  name: json['name'] as String?,
  withDiscount: json['withDiscount'] as bool?,
);

Map<String, dynamic> _$AutoShopServiceSearchObjectToJson(
  AutoShopServiceSearchObject instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  'name': instance.name,
  'withDiscount': instance.withDiscount,
};
