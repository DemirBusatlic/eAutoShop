// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_register.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRegister _$UserRegisterFromJson(Map<String, dynamic> json) => UserRegister(
  name: json['name'] as String,
  surname: json['surname'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  username: json['username'] as String,
  gender: json['gender'] as String,
  password: json['password'] as String,
  passwordConfirm: json['passwordConfirm'] as String,
  cityId: (json['cityId'] as num).toInt(),
  address: json['address'] as String?,
  postalCode: json['postalCode'] as String?,
  image: json['image'] as String?,
);

Map<String, dynamic> _$UserRegisterToJson(UserRegister instance) =>
    <String, dynamic>{
      'name': instance.name,
      'surname': instance.surname,
      'email': instance.email,
      'phone': instance.phone,
      'username': instance.username,
      'gender': instance.gender,
      'password': instance.password,
      'passwordConfirm': instance.passwordConfirm,
      'cityId': instance.cityId,
      'address': instance.address,
      'postalCode': instance.postalCode,
      'image': instance.image,
    };
