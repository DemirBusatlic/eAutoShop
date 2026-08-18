// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserUpdate _$UserUpdateFromJson(Map<String, dynamic> json) => UserUpdate(
  name: json['name'] as String?,
  surname: json['surname'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  gender: json['gender'] as String?,
  address: json['address'] as String?,
  postalCode: json['postalCode'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  image: json['image'] as String?,
);

Map<String, dynamic> _$UserUpdateToJson(UserUpdate instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'surname': ?instance.surname,
      'email': ?instance.email,
      'phone': ?instance.phone,
      'gender': ?instance.gender,
      'address': ?instance.address,
      'postalCode': ?instance.postalCode,
      'cityId': ?instance.cityId,
      'image': ?instance.image,
    };
