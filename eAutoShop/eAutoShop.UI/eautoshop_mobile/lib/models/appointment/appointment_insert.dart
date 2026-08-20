import 'package:json_annotation/json_annotation.dart';

part 'appointment_insert.g.dart';

@JsonSerializable()
class AppointmentInsert {
  int carModelId;
  int? orderId;
  DateTime reservationDate;
  List<int> services;

  AppointmentInsert({
    required this.carModelId,
    this.orderId,
    required this.reservationDate,
    required this.services,
  });

  factory AppointmentInsert.fromJson(Map<String, dynamic> json) =>
      _$AppointmentInsertFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentInsertToJson(this);
}
