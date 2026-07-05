import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/user_preference_model.dart';
import '../helpers/safe_json.dart';
import '../helpers/api_error_parser.dart';
import '../models/app_api_exception.dart';

AppApiException _appEx(String msg) => AppApiException(message: msg);

class PreferencesRepository {
  final ApiClient apiClient;

  PreferencesRepository({required this.apiClient});

  Future<UserPreferenceModel> fetchPreferences() async {
    try {
      final res = await apiClient.dio.get('/preferences/');
      final data = asMap(res.data);
      if (data == null) throw _appEx('فشل تحميل تفضيلات المستخدم');
      return UserPreferenceModel.fromJson(data);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل الاتصال بالخادم');
    }
  }

  Future<UserPreferenceModel> updatePreferences(Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.patch('/preferences/', data: data);
      final responseData = asMap(res.data);
      if (responseData == null) throw _appEx('فشل تحديث تفضيلات المستخدم');
      return UserPreferenceModel.fromJson(responseData);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل الاتصال بالخادم');
    }
  }
}
