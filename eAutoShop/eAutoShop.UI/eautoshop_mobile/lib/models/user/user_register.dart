import 'package:json_annotation/json_annotation.dart';

part 'user_register.g.dart';

@JsonSerializable()
class UserRegister {
  final String name;
  final String surname;
  final String email;
  final String phone;
  final String username;
  final String gender;
  final String password;
  final String passwordConfirm;
  final int cityId;

  final String? address;
  final String? postalCode;
  final String? image;

  const UserRegister({
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.username,
    required this.gender,
    required this.password,
    required this.passwordConfirm,
    required this.cityId,
    this.address,
    this.postalCode,
    this.image,
  });

  factory UserRegister.fromJson(Map<String, dynamic> json) =>
      _$UserRegisterFromJson(json);

  Map<String, dynamic> toJson() => _$UserRegisterToJson(this);
}
