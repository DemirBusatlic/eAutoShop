import 'package:json_annotation/json_annotation.dart';

part 'appointment_confirm.g.dart';

@JsonSerializable(includeIfNull: false)
class AppointmentConfirm {
  final int employeeId;
  final DateTime? estimatedCompletionDate;

  const AppointmentConfirm({
    required this.employeeId,
    this.estimatedCompletionDate,
  });

  factory AppointmentConfirm.fromJson(Map<String, dynamic> json) =>
      _$AppointmentConfirmFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentConfirmToJson(this);
}
