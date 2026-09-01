// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_models_by_manufacturer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarModelsByManufacturer _$CarModelsByManufacturerFromJson(
  Map<String, dynamic> json,
) => CarModelsByManufacturer(
  manufacturer: CarManufacturer.fromJson(
    json['manufacturer'] as Map<String, dynamic>,
  ),
  models: (json['models'] as List<dynamic>)
      .map((e) => CarModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CarModelsByManufacturerToJson(
  CarModelsByManufacturer instance,
) => <String, dynamic>{
  'manufacturer': instance.manufacturer.toJson(),
  'models': instance.models.map((e) => e.toJson()).toList(),
};
