import 'package:json_annotation/json_annotation.dart';

part 'employee_task_insert.g.dart';

@JsonSerializable(includeIfNull: false)
class EmployeeTaskInsert {
  final String title;
  final String description;
  final int employeeId;
  final DateTime? dueDate;

  const EmployeeTaskInsert({
    required this.title,
    required this.description,
    required this.employeeId,
    this.dueDate,
  });

  factory EmployeeTaskInsert.fromJson(Map<String, dynamic> json) =>
      _$EmployeeTaskInsertFromJson(json);

  Map<String, dynamic> toJson() => _$EmployeeTaskInsertToJson(this);
}
