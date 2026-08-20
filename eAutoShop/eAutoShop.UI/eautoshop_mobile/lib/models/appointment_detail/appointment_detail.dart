import 'package:json_annotation/json_annotation.dart';

part 'appointment_detail.g.dart';

@JsonSerializable()
class AppointmentDetail {
  int serviceId;
  String serviceName;
  double servicePrice;
  double serviceDiscount;
  double serviceDiscountedPrice;

  AppointmentDetail({
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDiscount,
    required this.serviceDiscountedPrice,
  });

  factory AppointmentDetail.fromJson(Map<String, dynamic> json) =>
      _$AppointmentDetailFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentDetailToJson(this);
}
