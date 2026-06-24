import '../helpers/safe_json.dart';
import 'user_model.dart';

class AuthResponse {
  final String? access;
  final String? refresh;
  final UserModel user;

  const AuthResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userData = asMap(json['user']);
    return AuthResponse(
      access: asString(json['access']),
      refresh: asString(json['refresh']),
      user: userData != null ? UserModel.fromJson(userData) : UserModel.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
        'access': access,
        'refresh': refresh,
        'user': user.toJson(),
      };
}
