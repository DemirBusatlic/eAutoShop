import 'package:json_annotation/json_annotation.dart';

part 'service_type_insert_update.g.dart';

@JsonSerializable(includeIfNull: false)
class ServiceTypeInsertUpdate {
  final String name;
  final String? image;

  const ServiceTypeInsertUpdate({required this.name, this.image});

  factory ServiceTypeInsertUpdate.fromJson(Map<String, dynamic> json) =>
      _$ServiceTypeInsertUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceTypeInsertUpdateToJson(this);
}
