import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/package_model.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class PackageRepository {
  final ApiClient apiClient;

  PackageRepository({required this.apiClient});

  Future<List<PackageModel>> fetchPackages() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.packages);
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }
      return asList(resultsList, (e) => PackageModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل الباقات');
    }
  }
  Future<PackageModel> createPackage(Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.packages, data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل إنشاء الباقة');
      return PackageModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل إنشاء الباقة');
    }
  }

  Future<PackageModel> updatePackage(int id, Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.patch('${ApiEndpoints.packages}$id/', data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل تعديل الباقة');
      return PackageModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تعديل الباقة');
    }
  }

  Future<void> deletePackage(int id) async {
    try {
      await apiClient.dio.delete('${ApiEndpoints.packages}$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل حذف الباقة');
    }
  }
}
