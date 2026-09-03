// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_shop_service_search_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutoShopServiceSearchObject _$AutoShopServiceSearchObjectFromJson(
  Map<String, dynamic> json,
) => AutoShopServiceSearchObject(
  serviceTypeId: (json['serviceTypeId'] as num?)?.toInt(),
  name: json['name'] as String?,
  withDiscount: json['withDiscount'] as bool?,
  state: json['state'] as String?,
);

Map<String, dynamic> _$AutoShopServiceSearchObjectToJson(
  AutoShopServiceSearchObject instance,
) => <String, dynamic>{
  'serviceTypeId': ?instance.serviceTypeId,
  'name': ?instance.name,
  'withDiscount': ?instance.withDiscount,
  'state': ?instance.state,
};
