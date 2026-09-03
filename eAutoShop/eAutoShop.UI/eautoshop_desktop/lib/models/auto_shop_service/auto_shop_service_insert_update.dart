import 'package:json_annotation/json_annotation.dart';

part 'auto_shop_service_insert_update.g.dart';

@JsonSerializable(includeIfNull: false)
class AutoShopServiceInsertUpdate {
  int? serviceTypeId;
  String? name;
  double? price;
  double? discount;
  String? imageData;
  String? description;
  String? details;
  String? duration;

  AutoShopServiceInsertUpdate({
    this.serviceTypeId,
    this.name,
    this.price,
    this.discount,
    this.imageData,
    this.description,
    this.details,
    this.duration,
  });

  factory AutoShopServiceInsertUpdate.fromJson(Map<String, dynamic> json) =>
      _$AutoShopServiceInsertUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AutoShopServiceInsertUpdateToJson(this);
}
