import 'package:json_annotation/json_annotation.dart';

part 'user_update.g.dart';

@JsonSerializable(includeIfNull: false)
class UserUpdate {
  final String? username;
  final String? name;
  final String? surname;
  final String? email;
  final String? phone;
  final String? gender;
  final String? address;
  final String? postalCode;
  final int? cityId;
  final int? roleId;
  final String? image;

  const UserUpdate({
    this.username,
    this.name,
    this.surname,
    this.email,
    this.phone,
    this.gender,
    this.address,
    this.postalCode,
    this.cityId,
    this.roleId,
    this.image,
  });

  factory UserUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$UserUpdateToJson(this);
}
