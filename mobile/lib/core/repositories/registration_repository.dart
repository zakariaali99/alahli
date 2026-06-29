import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/registration_model.dart';
import '../models/athlete_model.dart';
import '../models/paginated_response.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class RegistrationRepository {
  final ApiClient apiClient;

  RegistrationRepository({required this.apiClient});

  Future<PaginatedResponse<RegistrationModel>> fetchRegistrationsPaginated({
    String? status,
    String? roleChoice,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> query = {'page': page};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (roleChoice != null && roleChoice.isNotEmpty) query['role_choice'] = roleChoice;

      final res = await apiClient.dio.get(ApiEndpoints.registrations, queryParameters: query);
      final data = asMap(res.data);

      if (data != null && data['results'] != null) {
        return PaginatedResponse<RegistrationModel>(
          results: asList(data['results'], (e) => RegistrationModel.fromJson(asMap(e) ?? {})) ?? [],
          count: asInt(data['count']) ?? 0,
          next: asString(data['next']),
          previous: asString(data['previous']),
        );
      }

      final list = asList(res.data, (e) => RegistrationModel.fromJson(asMap(e) ?? {})) ?? [];
      return PaginatedResponse<RegistrationModel>(results: list, count: list.length);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل طلبات التسجيل');
    }
  }

  Future<List<RegistrationModel>> fetchRegistrations({
    String? status,
    String? roleChoice,
  }) async {
    return (await fetchRegistrationsPaginated(status: status, roleChoice: roleChoice)).results;
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
