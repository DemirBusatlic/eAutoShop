import 'package:json_annotation/json_annotation.dart';

part 'appointment_search_object.g.dart';

@JsonSerializable()
class AppointmentSearchObject {
  String? state;
  String? type;
  double? minTotalAmount;
  double? maxTotalAmount;
  bool? hasOrder;
  DateTime? minCreatedDate;
  DateTime? maxCreatedDate;
  DateTime? minReservationDate;
  DateTime? maxReservationDate;
  DateTime? minCompletionDate;
  DateTime? maxCompletionDate;

  AppointmentSearchObject({
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
