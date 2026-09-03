// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentDetail _$AppointmentDetailFromJson(Map<String, dynamic> json) =>
    AppointmentDetail(
      serviceId: (json['serviceId'] as num).toInt(),
      serviceName: json['serviceName'] as String,
      servicePrice: (json['servicePrice'] as num).toDouble(),
      serviceDiscount: (json['serviceDiscount'] as num).toDouble(),
      serviceDiscountedPrice: (json['serviceDiscountedPrice'] as num)
          .toDouble(),
    );

Map<String, dynamic> _$AppointmentDetailToJson(AppointmentDetail instance) =>
    <String, dynamic>{
      'serviceId': instance.serviceId,
      'serviceName': instance.serviceName,
      'servicePrice': instance.servicePrice,
      'serviceDiscount': instance.serviceDiscount,
      'serviceDiscountedPrice': instance.serviceDiscountedPrice,
    };
