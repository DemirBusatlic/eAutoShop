// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmployeeTask _$EmployeeTaskFromJson(Map<String, dynamic> json) => EmployeeTask(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  employeeId: (json['employeeId'] as num).toInt(),
  employeeName: json['employeeName'] as String,
  createdById: (json['createdById'] as num).toInt(),
  createdByName: json['createdByName'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  state: json['state'] as String,
);

Map<String, dynamic> _$EmployeeTaskToJson(EmployeeTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'employeeId': instance.employeeId,
      'employeeName': instance.employeeName,
      'createdById': instance.createdById,
      'createdByName': instance.createdByName,
      'createdAt': instance.createdAt.toIso8601String(),
      'dueDate': instance.dueDate?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'state': instance.state,
    };
