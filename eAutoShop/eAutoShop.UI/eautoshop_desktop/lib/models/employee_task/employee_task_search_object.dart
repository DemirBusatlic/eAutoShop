import 'package:json_annotation/json_annotation.dart';

part 'employee_task_search_object.g.dart';

@JsonSerializable(includeIfNull: false)
class EmployeeTaskSearchObject {
  final int? page;
  final int? pageSize;
  final String? titleFTS;
  final int? employeeId;
  final int? createdById;
  final String? state;
  final DateTime? minDueDate;
  final DateTime? maxDueDate;

  const EmployeeTaskSearchObject({
    this.page,
    this.pageSize,
    this.titleFTS,
    this.employeeId,
    this.createdById,
    this.state,
    this.minDueDate,
    this.maxDueDate,
  });

  factory EmployeeTaskSearchObject.fromJson(Map<String, dynamic> json) =>
      _$EmployeeTaskSearchObjectFromJson(json);

  Map<String, dynamic> toJson() => _$EmployeeTaskSearchObjectToJson(this);
}
