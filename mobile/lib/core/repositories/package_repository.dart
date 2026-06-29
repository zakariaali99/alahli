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
}
