// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  active: json['active'] as bool,
  name: json['name'] as String?,
  surname: json['surname'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  username: json['username'] as String?,
  gender: json['gender'] as String?,
  image: json['image'] as String?,
  address: json['address'] as String?,
  postalCode: json['postalCode'] as String?,
  cityId: (json['cityId'] as num?)?.toInt(),
  cityName: json['cityName'] as String?,
  roleId: (json['roleId'] as num?)?.toInt(),
  roleName: json['roleName'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'surname': instance.surname,
  'email': instance.email,
  'phone': instance.phone,
  'username': instance.username,
  'createdAt': instance.createdAt.toIso8601String(),
  'gender': instance.gender,
  'image': instance.image,
  'active': instance.active,
  'address': instance.address,
  'postalCode': instance.postalCode,
  'cityId': instance.cityId,
  'cityName': instance.cityName,
  'roleId': instance.roleId,
  'roleName': instance.roleName,
};
