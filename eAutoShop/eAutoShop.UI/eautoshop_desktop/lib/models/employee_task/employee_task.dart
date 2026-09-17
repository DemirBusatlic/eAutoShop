import 'package:json_annotation/json_annotation.dart';

part 'employee_task.g.dart';

@JsonSerializable()
class EmployeeTask {
  final int id;
  final String title;
  final String description;
  final int employeeId;
  final String employeeName;
  final int createdById;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String state;

  const EmployeeTask({
    required this.id,
    required this.title,
    required this.description,
    required this.employeeId,
    required this.employeeName,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    required this.state,
  });

  factory EmployeeTask.fromJson(Map<String, dynamic> json) =>
      _$EmployeeTaskFromJson(json);

  Map<String, dynamic> toJson() => _$EmployeeTaskToJson(this);
}
