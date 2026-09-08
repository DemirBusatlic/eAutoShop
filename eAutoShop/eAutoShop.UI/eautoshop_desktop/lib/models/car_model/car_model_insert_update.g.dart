// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_model_insert_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarModelInsertUpdate _$CarModelInsertUpdateFromJson(
  Map<String, dynamic> json,
) => CarModelInsertUpdate(
  name: json['name'] as String,
  modelYear: json['modelYear'] as String,
  carManufacturerId: (json['carManufacturerId'] as num).toInt(),
);

Map<String, dynamic> _$CarModelInsertUpdateToJson(
  CarModelInsertUpdate instance,
) => <String, dynamic>{
  'name': instance.name,
  'modelYear': instance.modelYear,
  'carManufacturerId': instance.carManufacturerId,
};
