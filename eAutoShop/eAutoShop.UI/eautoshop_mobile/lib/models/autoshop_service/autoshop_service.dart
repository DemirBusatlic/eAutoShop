import 'package:json_annotation/json_annotation.dart';

part 'autoshop_service.g.dart';

@JsonSerializable()
class AutoShopService {
  int id;
  int serviceTypeId;
  String serviceTypeName;
  String name;
  double price;
  double discount;
  double discountedPrice;
  String state;
  String? imageData;
  String description;
  String? details;
  String duration;

  AutoShopService({
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
