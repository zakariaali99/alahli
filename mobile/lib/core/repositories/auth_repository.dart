import '../network/api_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<AuthResponse> login(String phone, String password) async {
    final res = await _client.dio.post('/auth/login/', data: {
      'phone': phone,
      'password': password,
    });
    final authRes = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    _client.setTokens(
      access: authRes.access,
      refresh: authRes.refresh,
    );
    return authRes;
  }

  Future<void> logout() async {
    if (_client.isAuthenticated) {
      try {
        await _client.dio.post('/auth/logout/');
      } catch (_) {}
    }
    _client.clearTokens();
  }

  Future<UserModel> getMe() async {
    final res = await _client.dio.get('/auth/me/');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword(String oldPw, String newPw) async {
    await _client.dio.post('/auth/change-password/', data: {
      'old_password': oldPw,
      'new_password': newPw,
    });
  }
}
