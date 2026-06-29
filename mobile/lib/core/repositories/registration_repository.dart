import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/registration_model.dart';
import '../models/athlete_model.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class RegistrationRepository {
  final ApiClient apiClient;

  RegistrationRepository({required this.apiClient});

  Future<List<RegistrationModel>> fetchRegistrations({
    String? status,
    String? roleChoice,
  }) async {
    try {
      final Map<String, dynamic> query = {};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (roleChoice != null && roleChoice.isNotEmpty) query['role_choice'] = roleChoice;

      final res = await apiClient.dio.get(ApiEndpoints.registrations, queryParameters: query);
      
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }

      final list = asList(resultsList, (e) => RegistrationModel.fromJson(asMap(e) ?? {})) ?? [];
      return list;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل طلبات التسجيل');
    }
  }

  Future<void> approveRegistration(int id) async {
    try {
      await apiClient.dio.post(ApiEndpoints.approveRegistration(id));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل قبول طلب التسجيل');
    }
  }

  Future<void> rejectRegistration(int id) async {
    try {
      await apiClient.dio.post(ApiEndpoints.rejectRegistration(id));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل رفض طلب التسجيل');
    }
  }

  Future<AthleteModel> createAthleteProfile({
    required int registrationId,
    required FormData formData,
  }) async {
    try {
      final res = await apiClient.dio.post(
        ApiEndpoints.createAthleteProfile(registrationId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل إنشاء الملف الرياضي');
      return AthleteModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل إنشاء الملف الرياضي');
    }
  }
}
