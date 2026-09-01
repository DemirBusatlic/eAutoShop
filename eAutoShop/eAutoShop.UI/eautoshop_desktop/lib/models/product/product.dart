import 'package:eautoshop_desktop/models/car_model/car_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable(explicitToJson: true)
class Product {
  final int id;
  final String name;
  final double price;
  final String state;
  final double discount;
  final double discountedPrice;
  final String? imageData;
  final String? details;
  final List<CarModel>? carModels;
  final int? productCategoryId;
  final String? category;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.state,
    required this.discount,
    required this.discountedPrice,
    this.imageData,
    this.details,
    this.carModels,
    this.productCategoryId,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
