import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable()
class Appointment {
  final int id;
  final int customerId;
  final String customerUsername;
  final int? employeeId;
  final String? employeeUsername;

  @JsonKey(defaultValue: false)
  final bool hasStaffReview;

  final int? orderId;
  final String carModel;
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime reservationCreatedDate;
  final DateTime reservationDate;
  final DateTime? estimatedCompletionDate;
  final DateTime? completionDate;
  final double totalAmount;
  final String totalDuration;
  final String state;
  final String type;

  const Appointment({
    required this.id,
    required this.customerId,
    required this.customerUsername,
    this.employeeId,
    this.employeeUsername,
    this.hasStaffReview = false,
    this.orderId,
    required this.carModel,
    this.rejectionReason,
    this.cancellationReason,
    required this.reservationCreatedDate,
    required this.reservationDate,
    this.estimatedCompletionDate,
    this.completionDate,
    required this.totalAmount,
    required this.totalDuration,
    required this.state,
    required this.type,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentToJson(this);
}
