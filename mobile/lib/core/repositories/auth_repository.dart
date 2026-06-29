import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/user_model.dart';
import '../helpers/secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<UserModel> login({
    required String phone,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final res = await apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'phone': phone,
          'password': password,
          'remember_me': rememberMe,
        },
      );
      final data = asMap(res.data);
      if (data == null) throw Exception('بيانات تسجيل الدخول غير صالحة');

      final String? access = asString(data['access']);
      final String? refresh = asString(data['refresh']);
      final userJson = asMap(data['user']);

      if (access == null || refresh == null || userJson == null) {
        throw Exception('بيانات تسجيل الدخول غير صالحة');
      }

      final user = UserModel.fromJson(userJson);

      // Save tokens
      apiClient.setTokens(access: access, refresh: refresh);
      await SecureStorage.saveTokens(access: access, refresh: refresh);
      await SecureStorage.saveRememberMe(rememberMe);

      return user;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'خطأ في الاتصال بالخادم';
      throw Exception(detail);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.me);
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل جلب بيانات المستخدم');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل الاتصال بالخادم');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await apiClient.dio.post(
        ApiEndpoints.changePassword,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'حدث خطأ أثناء تغيير كلمة المرور';
      if (data is Map) {
        if (data.containsKey('old_password')) {
          msg = asString(data['old_password']) ?? msg;
        } else if (data.containsKey('new_password')) {
          final list = data['new_password'];
          if (list is List && list.isNotEmpty) {
            msg = list.first.toString();
          }
        } else if (data.containsKey('detail')) {
          msg = asString(data['detail']) ?? msg;
        }
      }
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await SecureStorage.getRefreshToken();
      if (refresh != null) {
        await apiClient.dio.post(ApiEndpoints.logout, data: {'refresh': refresh});
      }
    } catch (_) {
      // Best effort
    } finally {
      apiClient.clearTokens();
      await SecureStorage.clearAll();
    }
  }
}
