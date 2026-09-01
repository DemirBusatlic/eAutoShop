// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  state: json['state'] as String,
  discount: (json['discount'] as num).toDouble(),
  discountedPrice: (json['discountedPrice'] as num).toDouble(),
  imageData: json['imageData'] as String?,
  details: json['details'] as String?,
  carModels: (json['carModels'] as List<dynamic>?)
      ?.map((e) => CarModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  productCategoryId: (json['productCategoryId'] as num?)?.toInt(),
  category: json['category'] as String?,
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'price': instance.price,
  'state': instance.state,
  'discount': instance.discount,
  'discountedPrice': instance.discountedPrice,
  'imageData': instance.imageData,
  'details': instance.details,
  'carModels': instance.carModels?.map((e) => e.toJson()).toList(),
  'productCategoryId': instance.productCategoryId,
  'category': instance.category,
};
