// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_change_password.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserChangePassword _$UserChangePasswordFromJson(Map<String, dynamic> json) =>
    UserChangePassword(
      oldPassword: json['oldPassword'] as String,
      newPassword: json['newPassword'] as String,
      confirmNewPassword: json['confirmNewPassword'] as String,
    );

Map<String, dynamic> _$UserChangePasswordToJson(UserChangePassword instance) =>
    <String, dynamic>{
      'oldPassword': instance.oldPassword,
      'newPassword': instance.newPassword,
      'confirmNewPassword': instance.confirmNewPassword,
    };
