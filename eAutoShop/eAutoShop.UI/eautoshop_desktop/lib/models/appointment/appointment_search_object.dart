import 'package:json_annotation/json_annotation.dart';

part 'appointment_search_object.g.dart';

@JsonSerializable(includeIfNull: false)
class AppointmentSearchObject {
  final String? customerUsername;
  final String? employeeUsername;
  final String? state;
  final String? type;
  final double? minTotalAmount;
  final double? maxTotalAmount;
  final bool? hasOrder;
  final DateTime? minCreatedDate;
  final DateTime? maxCreatedDate;
  final DateTime? minReservationDate;
  final DateTime? maxReservationDate;
  final DateTime? minCompletionDate;
  final DateTime? maxCompletionDate;

  const AppointmentSearchObject({
    this.customerUsername,
    this.employeeUsername,
    this.state,
    this.type,
    this.minTotalAmount,
    this.maxTotalAmount,
    this.hasOrder,
    this.minCreatedDate,
    this.maxCreatedDate,
    this.minReservationDate,
    this.maxReservationDate,
    this.minCompletionDate,
    this.maxCompletionDate,
  });

  factory AppointmentSearchObject.fromJson(Map<String, dynamic> json) =>
      _$AppointmentSearchObjectFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentSearchObjectToJson(this);
}
