import 'package:json_annotation/json_annotation.dart';

part 'autoshop_service_search_object.g.dart';

@JsonSerializable()
class AutoShopServiceSearchObject {
  String? serviceType;
  String? name;
  bool? withDiscount;

  AutoShopServiceSearchObject({this.serviceType, this.name, this.withDiscount});

  factory AutoShopServiceSearchObject.fromJson(Map<String, dynamic> json) =>
      _$AutoShopServiceSearchObjectFromJson(json);

  Map<String, dynamic> toJson() => _$AutoShopServiceSearchObjectToJson(this);
}
