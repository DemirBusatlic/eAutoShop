// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
  id: (json['id'] as num).toInt(),
  customerId: (json['customerId'] as num).toInt(),
  customerUsername: json['customerUsername'] as String,
  employeeId: (json['employeeId'] as num?)?.toInt(),
  employeeUsername: json['employeeUsername'] as String?,
  orderId: (json['orderId'] as num?)?.toInt(),
  carModel: json['carModel'] as String,
  rejectionReason: json['rejectionReason'] as String?,
  cancellationReason: json['cancellationReason'] as String?,
  reservationCreatedDate: DateTime.parse(
    json['reservationCreatedDate'] as String,
  ),
  reservationDate: DateTime.parse(json['reservationDate'] as String),
  estimatedCompletionDate: json['estimatedCompletionDate'] == null
      ? null
      : DateTime.parse(json['estimatedCompletionDate'] as String),
  completionDate: json['completionDate'] == null
      ? null
      : DateTime.parse(json['completionDate'] as String),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  totalDuration: json['totalDuration'] as String,
  state: json['state'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$AppointmentToJson(
  Appointment instance,
) => <String, dynamic>{
  'id': instance.id,
  'customerId': instance.customerId,
  'customerUsername': instance.customerUsername,
  'employeeId': instance.employeeId,
  'employeeUsername': instance.employeeUsername,
  'orderId': instance.orderId,
  'carModel': instance.carModel,
  'rejectionReason': instance.rejectionReason,
  'cancellationReason': instance.cancellationReason,
  'reservationCreatedDate': instance.reservationCreatedDate.toIso8601String(),
  'reservationDate': instance.reservationDate.toIso8601String(),
  'estimatedCompletionDate': instance.estimatedCompletionDate
      ?.toIso8601String(),
  'completionDate': instance.completionDate?.toIso8601String(),
  'totalAmount': instance.totalAmount,
  'totalDuration': instance.totalDuration,
  'state': instance.state,
  'type': instance.type,
};
