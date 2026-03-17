import 'package:json_annotation/json_annotation.dart';
import 'package:organiq/modules/auth/data/models/auth_user_model.dart';

part 'auth_session_output.g.dart';

@JsonSerializable()
class AuthSessionOutput {
  const AuthSessionOutput({required this.token, required this.user});

  final String token;
  final AuthUserModel user;

  factory AuthSessionOutput.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionOutputFromJson(json);

  Map<String, dynamic> toJson() => _$AuthSessionOutputToJson(this);
}
