import 'package:json_annotation/json_annotation.dart';

part 'product_category.g.dart';

@JsonSerializable()
class ProductCategory {
  int id;
  String name;

  ProductCategory(this.id, this.name);

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ProductCategoryToJson(this);
}
