// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarModel _$CarModelFromJson(Map<String, dynamic> json) => CarModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  modelYear: json['modelYear'] as String,
);

Map<String, dynamic> _$CarModelToJson(CarModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'modelYear': instance.modelYear,
};
