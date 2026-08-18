import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String? name;
  final String? surname;
  final String? email;
  final String? phone;
  final String? username;
  final DateTime createdAt;
  final String? gender;
  final String? image;
  final bool active;
  final String? address;
  final String? postalCode;
  final int? cityId;
  final String? cityName;
  final int? roleId;
  final String? roleName;

  const User({
    required this.id,
    required this.createdAt,
    required this.active,
    this.name,
    this.surname,
    this.email,
    this.phone,
    this.username,
    this.gender,
    this.image,
    this.address,
    this.postalCode,
    this.cityId,
    this.cityName,
    this.roleId,
    this.roleName,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
