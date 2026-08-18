import 'package:eautoshop_mobile/models/car_model/car_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  int id;
  String name;
  double price;
  String state;
  double discount;
  double discountedPrice;
  String? imageData;
  String? details;
  List<CarModel>? carModels;
  int? productCategoryId;
  String? category;

  Product(
    this.id,
    this.name,
    this.price,
    this.state,
    this.discount,
    this.discountedPrice,
    this.imageData,
    this.details,
    this.carModels,
    this.productCategoryId,
    this.category,
  );

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
