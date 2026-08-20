// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentUpdate _$AppointmentUpdateFromJson(Map<String, dynamic> json) =>
    AppointmentUpdate(
      reservationDate: json['reservationDate'] == null
          ? null
          : DateTime.parse(json['reservationDate'] as String),
    );

Map<String, dynamic> _$AppointmentUpdateToJson(AppointmentUpdate instance) =>
    <String, dynamic>{
      'reservationDate': instance.reservationDate?.toIso8601String(),
    };
