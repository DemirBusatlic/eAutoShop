import 'package:json_annotation/json_annotation.dart';

part 'catalog_name_request.g.dart';

@JsonSerializable()
class CatalogNameRequest {
  final String name;

  const CatalogNameRequest({required this.name});

  factory CatalogNameRequest.fromJson(Map<String, dynamic> json) =>
      _$CatalogNameRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogNameRequestToJson(this);
}
