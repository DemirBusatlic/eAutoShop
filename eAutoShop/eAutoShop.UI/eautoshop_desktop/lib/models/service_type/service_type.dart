import 'package:json_annotation/json_annotation.dart';

part 'service_type.g.dart';

@JsonSerializable()
class ServiceType {
  final int id;
  final String name;
  final String image;

  const ServiceType({
    required this.id,
    required this.name,
    required this.image,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) =>
      _$ServiceTypeFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceTypeToJson(this);
}
