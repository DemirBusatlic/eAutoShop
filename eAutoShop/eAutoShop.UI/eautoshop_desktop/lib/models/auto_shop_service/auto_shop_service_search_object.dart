import 'package:json_annotation/json_annotation.dart';

part 'auto_shop_service_search_object.g.dart';

@JsonSerializable(includeIfNull: false)
class AutoShopServiceSearchObject {
  final int? serviceTypeId;
  final String? name;
  final bool? withDiscount;
  final String? state;

  const AutoShopServiceSearchObject({
    this.serviceTypeId,
    this.name,
    this.withDiscount,
    this.state,
  });

  factory AutoShopServiceSearchObject.fromJson(Map<String, dynamic> json) =>
      _$AutoShopServiceSearchObjectFromJson(json);

  Map<String, dynamic> toJson() => _$AutoShopServiceSearchObjectToJson(this);
}
