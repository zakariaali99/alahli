import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/user_model.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class StaffRepository {
  final ApiClient apiClient;

  StaffRepository({required this.apiClient});

  Future<List<UserModel>> fetchStaff({
    String? search,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> query = {};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (role != null && role.isNotEmpty) query['role'] = role;

      final res = await apiClient.dio.get(ApiEndpoints.users, queryParameters: query);
      
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }

      final list = asList(resultsList, (e) => UserModel.fromJson(asMap(e) ?? {})) ?? [];
      // Filter out athlete and parent roles to only show management staff
      return list.where((user) => user.role != 'athlete' && user.role != 'parent').toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل الموظفين');
    }
  }

  Future<UserModel> createStaff(Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.users, data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل إنشاء حساب الموظف');
      return UserModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل إضافة موظف جديد');
    }
  }

  Future<UserModel> updateStaff(int id, Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.patch('${ApiEndpoints.users}$id/', data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل تعديل حساب الموظف');
      return UserModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تعديل حساب الموظف');
    }
  }

  Future<void> deleteStaff(int id) async {
    try {
      await apiClient.dio.delete('${ApiEndpoints.users}$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل حذف حساب الموظف');
    }
  }
}
