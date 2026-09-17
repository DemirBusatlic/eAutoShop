// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_task_search_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmployeeTaskSearchObject _$EmployeeTaskSearchObjectFromJson(
  Map<String, dynamic> json,
) => EmployeeTaskSearchObject(
  page: (json['page'] as num?)?.toInt(),
  pageSize: (json['pageSize'] as num?)?.toInt(),
  titleFTS: json['titleFTS'] as String?,
  employeeId: (json['employeeId'] as num?)?.toInt(),
  createdById: (json['createdById'] as num?)?.toInt(),
  state: json['state'] as String?,
  minDueDate: json['minDueDate'] == null
      ? null
      : DateTime.parse(json['minDueDate'] as String),
  maxDueDate: json['maxDueDate'] == null
      ? null
      : DateTime.parse(json['maxDueDate'] as String),
);

Map<String, dynamic> _$EmployeeTaskSearchObjectToJson(
  EmployeeTaskSearchObject instance,
) => <String, dynamic>{
  'page': ?instance.page,
  'pageSize': ?instance.pageSize,
  'titleFTS': ?instance.titleFTS,
  'employeeId': ?instance.employeeId,
  'createdById': ?instance.createdById,
  'state': ?instance.state,
  'minDueDate': ?instance.minDueDate?.toIso8601String(),
  'maxDueDate': ?instance.maxDueDate?.toIso8601String(),
};
