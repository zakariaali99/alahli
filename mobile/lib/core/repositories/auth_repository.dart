import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/user_model.dart';
import '../helpers/secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';
import '../helpers/api_error_parser.dart';
import '../models/app_api_exception.dart';

AppApiException _appEx(String msg) => AppApiException(message: msg);

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<UserModel> login({
    required String phone,
    String password = '',
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
      if (data == null) throw _appEx('بيانات تسجيل الدخول غير صالحة');

      final String? access = asString(data['access']);
      final String? refresh = asString(data['refresh']);
      final userJson = asMap(data['user']);

      if (access == null || refresh == null || userJson == null) {
        throw _appEx('بيانات تسجيل الدخول غير صالحة');
      }

      final user = UserModel.fromJson(userJson);

      // Save tokens
      apiClient.setTokens(access: access, refresh: refresh);
      await SecureStorage.saveTokens(access: access, refresh: refresh);
      await SecureStorage.saveRememberMe(rememberMe);

      return user;
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'خطأ في الاتصال بالخادم');
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? whatsappPhone,
    String? residence,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['first_name_ar'] = name;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (whatsappPhone != null) body['whatsapp_phone'] = whatsappPhone;
      if (residence != null) body['residence'] = residence;

      final res = await apiClient.dio.patch(ApiEndpoints.profile, data: body);
      final data = asMap(res.data);
      if (data == null) throw _appEx('فشل تحديث البيانات');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل تحديث البيانات الشخصية');
    }
  }


  Future<UserModel> getMe() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.me);
      final data = asMap(res.data);
      if (data == null) throw _appEx('فشل جلب بيانات المستخدم');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل الاتصال بالخادم');
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
      throw dioToAppApiException(e, fallback: 'حدث خطأ أثناء تغيير كلمة المرور');
    }
  }

  Future<void> deleteRejectedAccount() async {
    await apiClient.dio.post(ApiEndpoints.deleteRejectedAccount);
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
