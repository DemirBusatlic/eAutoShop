import 'package:json_annotation/json_annotation.dart';

part 'user_change_password.g.dart';

@JsonSerializable()
class UserChangePassword {
  final String oldPassword;
  final String newPassword;
  final String confirmNewPassword;

  const UserChangePassword({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  factory UserChangePassword.fromJson(Map<String, dynamic> json) =>
      _$UserChangePasswordFromJson(json);

  Map<String, dynamic> toJson() => _$UserChangePasswordToJson(this);
}
