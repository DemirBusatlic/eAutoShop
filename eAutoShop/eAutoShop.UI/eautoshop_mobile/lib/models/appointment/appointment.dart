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

  int? orderId;
  String carModel;
  String? rejectionReason;
  String? cancellationReason;
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
