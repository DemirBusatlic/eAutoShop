import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable()
class Appointment {
  int id;
  int customerId;
  String customerUsername;
  int? employeeId;
  String? employeeUsername;

  @JsonKey(defaultValue: false)
  bool hasStaffReview;

  String carModel;
  String? rejectionReason;
  String? cancellationReason;
  String? confirmedBy;
  DateTime? confirmedAt;
  String? rejectedBy;
  DateTime? rejectedAt;
  String? cancelledBy;
  DateTime? cancelledAt;
  String? startedBy;
  DateTime? startedAt;
  String? completedBy;
  DateTime reservationCreatedDate;
  DateTime reservationDate;
  DateTime? estimatedCompletionDate;
  DateTime? completionDate;
  double totalAmount;
  String totalDuration;
  String state;
  String type;

  Appointment({
    required this.id,
    required this.customerId,
    required this.customerUsername,
    this.employeeId,
    this.employeeUsername,
    this.hasStaffReview = false,
    required this.carModel,
    this.rejectionReason,
    this.cancellationReason,
    this.confirmedBy,
    this.confirmedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.cancelledBy,
    this.cancelledAt,
    this.startedBy,
    this.startedAt,
    this.completedBy,
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
