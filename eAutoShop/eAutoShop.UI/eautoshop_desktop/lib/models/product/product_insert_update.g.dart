// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_insert_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductInsertUpdate _$ProductInsertUpdateFromJson(Map<String, dynamic> json) =>
    ProductInsertUpdate(
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      imageData: json['imageData'] as String?,
      description: json['description'] as String?,
      carModelIds: (json['carModelIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      productCategoryId: (json['productCategoryId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductInsertUpdateToJson(
  ProductInsertUpdate instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'price': ?instance.price,
  'discount': ?instance.discount,
  'imageData': ?instance.imageData,
  'description': ?instance.description,
  'carModelIds': ?instance.carModelIds,
  'productCategoryId': ?instance.productCategoryId,
};
