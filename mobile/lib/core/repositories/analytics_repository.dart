import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/dashboard_stats.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class AnalyticsRepository {
  final ApiClient apiClient;

  AnalyticsRepository({required this.apiClient});

  Future<DashboardStats> fetchStats({int? academyId}) async {
    try {
      final Map<String, dynamic> query = {};
      if (academyId != null) query['academy_id'] = academyId;

      final res = await apiClient.dio.get(ApiEndpoints.analyticsStats, queryParameters: query);
      final data = asMap(res.data);
      if (data == null) throw Exception('بيانات الإحصائيات غير صالحة');
      return DashboardStats.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل إحصائيات لوحة القيادة');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMonthlyGrowth() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.analyticsMonthlyGrowth);
      return asList(res.data, (e) => asMap(e) ?? {}) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل نمو اللاعبين الشهري');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDepartmentDistribution() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.analyticsDepartmentDistribution);
      return asList(res.data, (e) => asMap(e) ?? {}) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل توزيع اللاعبين على الأكاديميات');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRevenue() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.analyticsRevenue);
      return asList(res.data, (e) => asMap(e) ?? {}) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل تقرير الإيرادات');
    }
  }
}
