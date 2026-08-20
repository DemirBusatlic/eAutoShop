import 'package:json_annotation/json_annotation.dart';

part 'appointment_update.g.dart';

@JsonSerializable()
class AppointmentUpdate {
  DateTime? reservationDate;

  AppointmentUpdate({this.reservationDate});

  factory AppointmentUpdate.fromJson(Map<String, dynamic> json) =>
      _$AppointmentUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentUpdateToJson(this);
}
