import 'package:json_annotation/json_annotation.dart';

part 'auto_shop_service.g.dart';

@JsonSerializable()
class AutoShopService {
  final int id;
  final int serviceTypeId;
  final String serviceTypeName;
  final String name;
  final double price;
  final double discount;
  final double discountedPrice;
  final String state;
  final String? imageData;
  final String description;
  final String? details;
  final String duration;

  const AutoShopService({
    required this.id,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.name,
    required this.price,
    required this.discount,
    required this.discountedPrice,
    required this.state,
    this.imageData,
    required this.description,
    this.details,
    required this.duration,
  });

  factory AutoShopService.fromJson(Map<String, dynamic> json) =>
      _$AutoShopServiceFromJson(json);

  Map<String, dynamic> toJson() => _$AutoShopServiceToJson(this);
}
