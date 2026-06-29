import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/athlete_model.dart';
import '../models/paginated_response.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class AthleteRepository {
  final ApiClient apiClient;

  AthleteRepository({required this.apiClient});

  Future<PaginatedResponse<AthleteModel>> fetchAthletesPaginated({
    String? search,
    int? departmentId,
    bool? isActive,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> query = {'page': page};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (departmentId != null) query['department'] = departmentId;
      if (isActive != null) query['is_active'] = isActive;

      final res = await apiClient.dio.get(ApiEndpoints.athletes, queryParameters: query);
      final data = asMap(res.data);

      if (data != null && data['results'] != null) {
        return PaginatedResponse<AthleteModel>(
          results: asList(data['results'], (e) => AthleteModel.fromJson(asMap(e) ?? {})) ?? [],
          count: asInt(data['count']) ?? 0,
          next: asString(data['next']),
          previous: asString(data['previous']),
        );
      }

      final list = asList(res.data, (e) => AthleteModel.fromJson(asMap(e) ?? {})) ?? [];
      return PaginatedResponse<AthleteModel>(results: list, count: list.length);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل اللاعبين');
    }
  }

  Future<List<AthleteModel>> fetchAthletes({
    String? search,
    int? departmentId,
    bool? isActive,
  }) async {
    return (await fetchAthletesPaginated(
      search: search,
      departmentId: departmentId,
      isActive: isActive,
    )).results;
  }

  Future<AthleteModel> fetchAthlete(int id) async {
    try {
      final res = await apiClient.dio.get('${ApiEndpoints.athletes}$id/');
      final data = asMap(res.data);
      if (data == null) throw Exception('بيانات اللاعب غير صالحة');
      return AthleteModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل تفاصيل اللاعب');
    }
  }

  Future<AthleteModel> createAthlete(FormData formData) async {
    try {
      final res = await apiClient.dio.post(
        ApiEndpoints.athletes,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل إنشاء اللاعب');
      return AthleteModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل إضافة لاعب جديد');
    }
  }

  Future<AthleteModel> updateAthlete(int id, FormData formData) async {
    try {
      final res = await apiClient.dio.patch(
        '${ApiEndpoints.athletes}$id/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل تحديث اللاعب');
      return AthleteModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تعديل بيانات اللاعب');
    }
  }

  Future<void> deleteAthlete(int id) async {
    try {
      await apiClient.dio.delete('${ApiEndpoints.athletes}$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل حذف اللاعب');
    }
  }

  Future<Map<String, dynamic>> verifyMembership(String membershipNumber) async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.verifyAthlete(membershipNumber));
      return asMap(res.data) ?? {};
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'رقم العضوية غير صحيح أو غير منشط');
    }
  }
}
