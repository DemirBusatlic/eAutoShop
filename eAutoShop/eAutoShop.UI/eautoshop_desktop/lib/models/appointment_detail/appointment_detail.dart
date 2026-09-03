import 'package:json_annotation/json_annotation.dart';

part 'appointment_detail.g.dart';

@JsonSerializable()
class AppointmentDetail {
  final int serviceId;
  final String serviceName;
  final double servicePrice;
  final double serviceDiscount;
  final double serviceDiscountedPrice;

  const AppointmentDetail({
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
