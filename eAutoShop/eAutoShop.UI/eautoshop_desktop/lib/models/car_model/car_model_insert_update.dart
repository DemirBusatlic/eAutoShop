import 'package:json_annotation/json_annotation.dart';

part 'car_model_insert_update.g.dart';

@JsonSerializable()
class CarModelInsertUpdate {
  final String name;
  final String modelYear;
  final int carManufacturerId;

  const CarModelInsertUpdate({
    required this.name,
    required this.modelYear,
    required this.carManufacturerId,
  });

  factory CarModelInsertUpdate.fromJson(Map<String, dynamic> json) =>
      _$CarModelInsertUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$CarModelInsertUpdateToJson(this);
}
