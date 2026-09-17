// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_task_insert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmployeeTaskInsert _$EmployeeTaskInsertFromJson(Map<String, dynamic> json) =>
    EmployeeTaskInsert(
      title: json['title'] as String,
      description: json['description'] as String,
      employeeId: (json['employeeId'] as num).toInt(),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
    );

Map<String, dynamic> _$EmployeeTaskInsertToJson(EmployeeTaskInsert instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'employeeId': instance.employeeId,
      'dueDate': ?instance.dueDate?.toIso8601String(),
    };
