import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/department_model.dart';
import '../models/sport_model.dart';
import '../models/group_model.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class DepartmentRepository {
  final ApiClient apiClient;

  DepartmentRepository({required this.apiClient});

  Future<List<DepartmentModel>> fetchDepartments() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.departments);
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }
      return asList(resultsList, (e) => DepartmentModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل الأكاديميات');
    }
  }

  Future<DepartmentModel> createDepartment(FormData formData) async {
    try {
      final res = await apiClient.dio.post(
        ApiEndpoints.departments,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل إنشاء الأكاديمية');
      return DepartmentModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل إضافة أكاديمية جديدة');
    }
  }

  Future<DepartmentModel> updateDepartment(int id, FormData formData) async {
    try {
      final res = await apiClient.dio.patch(
        '${ApiEndpoints.departments}$id/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل تعديل الأكاديمية');
      return DepartmentModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تعديل الأكاديمية');
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      await apiClient.dio.delete('${ApiEndpoints.departments}$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل حذف الأكاديمية');
    }
  }

  Future<List<SportModel>> fetchSports() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.sports);
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }
      return asList(resultsList, (e) => SportModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل الرياضات');
    }
  }

  Future<List<SportModel>> fetchSportsByDepartment(int departmentId) async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.sports, queryParameters: {'department': departmentId});
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }
      return asList(resultsList, (e) => SportModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل رياضات الأكاديمية');
    }
  }

  Future<SportModel> createSport(Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.sports, data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل إنشاء الرياضة');
      return SportModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل إضافة رياضة جديدة');
    }
  }

  Future<SportModel> updateSport(int id, Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.patch('${ApiEndpoints.sports}$id/', data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل تعديل الرياضة');
      return SportModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تعديل الرياضة');
    }
  }

  Future<void> deleteSport(int id) async {
    try {
      await apiClient.dio.delete('${ApiEndpoints.sports}$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل حذف الرياضة');
    }
  }

  Future<List<GroupModel>> fetchGroups() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.groups);
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }
      return asList(resultsList, (e) => GroupModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل المجموعات');
    }
  }

  Future<List<GroupModel>> fetchGroupsBySport(int sportId) async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.groups, queryParameters: {'sport': sportId});
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }
      return asList(resultsList, (e) => GroupModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل مجموعات الرياضة');
    }
  }

  Future<GroupModel> createGroup(Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.groups, data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل إنشاء المجموعة');
      return GroupModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل إضافة مجموعة جديدة');
    }
  }

  Future<GroupModel> updateGroup(int id, Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.patch('${ApiEndpoints.groups}$id/', data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل تعديل المجموعة');
      return GroupModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تعديل المجموعة');
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await apiClient.dio.delete('${ApiEndpoints.groups}$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل حذف المجموعة');
    }
  }
}
