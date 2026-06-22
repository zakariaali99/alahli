import 'user_model.dart';

class AuthResponse {
  final String access;
  final String refresh;
  final UserModel user;

  const AuthResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'access': access,
        'refresh': refresh,
        'user': user.toJson(),
      };
}
