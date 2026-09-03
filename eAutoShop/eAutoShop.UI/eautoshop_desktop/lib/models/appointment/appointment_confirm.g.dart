// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_confirm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentConfirm _$AppointmentConfirmFromJson(Map<String, dynamic> json) =>
    AppointmentConfirm(
      employeeId: (json['employeeId'] as num).toInt(),
      estimatedCompletionDate: json['estimatedCompletionDate'] == null
          ? null
          : DateTime.parse(json['estimatedCompletionDate'] as String),
    );

Map<String, dynamic> _$AppointmentConfirmToJson(AppointmentConfirm instance) =>
    <String, dynamic>{
      'employeeId': instance.employeeId,
      'estimatedCompletionDate': ?instance.estimatedCompletionDate
          ?.toIso8601String(),
    };
