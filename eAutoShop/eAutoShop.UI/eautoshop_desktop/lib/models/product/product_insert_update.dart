import 'package:json_annotation/json_annotation.dart';

part 'product_insert_update.g.dart';

@JsonSerializable(includeIfNull: false)
class ProductInsertUpdate {
  String? name;
  double? price;
  double? discount;
  String? imageData;
  String? description;
  List<int>? carModelIds;
  int? productCategoryId;

  ProductInsertUpdate({
    this.name,
    this.price,
    this.discount,
    this.imageData,
    this.description,
    this.carModelIds,
    this.productCategoryId,
  });

  factory ProductInsertUpdate.fromJson(Map<String, dynamic> json) =>
      _$ProductInsertUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ProductInsertUpdateToJson(this);
}
