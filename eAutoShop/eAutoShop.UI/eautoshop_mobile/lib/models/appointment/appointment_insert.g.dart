// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_insert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentInsert _$AppointmentInsertFromJson(Map<String, dynamic> json) =>
    AppointmentInsert(
      carModelId: (json['carModelId'] as num).toInt(),
      orderId: (json['orderId'] as num?)?.toInt(),
      reservationDate: DateTime.parse(json['reservationDate'] as String),
      services: (json['services'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$AppointmentInsertToJson(AppointmentInsert instance) =>
    <String, dynamic>{
      'carModelId': instance.carModelId,
      'orderId': instance.orderId,
      'reservationDate': instance.reservationDate.toIso8601String(),
      'services': instance.services,
    };
