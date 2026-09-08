import 'package:json_annotation/json_annotation.dart';

part 'car_model.g.dart';

@JsonSerializable()
class CarModel {
  final int id;
  final String name;
  final String modelYear;
  final int carManufacturerId;
  final String carManufacturerName;

  const CarModel({
    required this.id,
    required this.name,
    required this.modelYear,
    required this.carManufacturerId,
    required this.carManufacturerName,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) =>
      _$CarModelFromJson(json);

  Map<String, dynamic> toJson() => _$CarModelToJson(this);
}
