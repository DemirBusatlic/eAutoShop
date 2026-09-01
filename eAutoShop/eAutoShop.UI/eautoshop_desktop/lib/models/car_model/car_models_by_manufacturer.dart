import 'package:eautoshop_desktop/models/car_manufacturer/car_manufacturer.dart';
import 'package:eautoshop_desktop/models/car_model/car_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'car_models_by_manufacturer.g.dart';

@JsonSerializable(explicitToJson: true)
class CarModelsByManufacturer {
  final CarManufacturer manufacturer;
  final List<CarModel> models;

  const CarModelsByManufacturer({
    required this.manufacturer,
    required this.models,
  });

  factory CarModelsByManufacturer.fromJson(Map<String, dynamic> json) =>
      _$CarModelsByManufacturerFromJson(json);

  Map<String, dynamic> toJson() => _$CarModelsByManufacturerToJson(this);
}
