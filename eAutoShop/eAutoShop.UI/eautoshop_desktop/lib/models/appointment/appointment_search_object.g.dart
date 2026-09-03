// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_search_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentSearchObject _$AppointmentSearchObjectFromJson(
  Map<String, dynamic> json,
) => AppointmentSearchObject(
  customerUsername: json['customerUsername'] as String?,
  employeeUsername: json['employeeUsername'] as String?,
  state: json['state'] as String?,
  type: json['type'] as String?,
  minTotalAmount: (json['minTotalAmount'] as num?)?.toDouble(),
  maxTotalAmount: (json['maxTotalAmount'] as num?)?.toDouble(),
  hasOrder: json['hasOrder'] as bool?,
  minCreatedDate: json['minCreatedDate'] == null
      ? null
      : DateTime.parse(json['minCreatedDate'] as String),
  maxCreatedDate: json['maxCreatedDate'] == null
      ? null
      : DateTime.parse(json['maxCreatedDate'] as String),
  minReservationDate: json['minReservationDate'] == null
      ? null
      : DateTime.parse(json['minReservationDate'] as String),
  maxReservationDate: json['maxReservationDate'] == null
      ? null
      : DateTime.parse(json['maxReservationDate'] as String),
  minCompletionDate: json['minCompletionDate'] == null
      ? null
      : DateTime.parse(json['minCompletionDate'] as String),
  maxCompletionDate: json['maxCompletionDate'] == null
      ? null
      : DateTime.parse(json['maxCompletionDate'] as String),
);

Map<String, dynamic> _$AppointmentSearchObjectToJson(
  AppointmentSearchObject instance,
) => <String, dynamic>{
  'customerUsername': ?instance.customerUsername,
  'employeeUsername': ?instance.employeeUsername,
  'state': ?instance.state,
  'type': ?instance.type,
  'minTotalAmount': ?instance.minTotalAmount,
  'maxTotalAmount': ?instance.maxTotalAmount,
  'hasOrder': ?instance.hasOrder,
  'minCreatedDate': ?instance.minCreatedDate?.toIso8601String(),
  'maxCreatedDate': ?instance.maxCreatedDate?.toIso8601String(),
  'minReservationDate': ?instance.minReservationDate?.toIso8601String(),
  'maxReservationDate': ?instance.maxReservationDate?.toIso8601String(),
  'minCompletionDate': ?instance.minCompletionDate?.toIso8601String(),
  'maxCompletionDate': ?instance.maxCompletionDate?.toIso8601String(),
};
