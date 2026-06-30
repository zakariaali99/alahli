import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/user_preference_model.dart';
import '../helpers/safe_json.dart';

class PreferencesRepository {
  final ApiClient apiClient;

  PreferencesRepository({required this.apiClient});

  Future<UserPreferenceModel> fetchPreferences() async {
    try {
      final res = await apiClient.dio.get('/preferences/');
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل تحميل تفضيلات المستخدم');
      return UserPreferenceModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل الاتصال بالخادم');
    }
  }

  Future<UserPreferenceModel> updatePreferences(Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.patch('/preferences/', data: data);
      final responseData = asMap(res.data);
      if (responseData == null) throw Exception('فشل تحديث تفضيلات المستخدم');
      return UserPreferenceModel.fromJson(responseData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل الاتصال بالخادم');
    }
  }
}
