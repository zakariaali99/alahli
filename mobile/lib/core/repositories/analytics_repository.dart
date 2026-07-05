import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/dashboard_stats.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class AnalyticsRepository {
  final ApiClient apiClient;

  AnalyticsRepository({required this.apiClient});

  Map<String, dynamic>? _extractMapPayload(dynamic raw) {
    final root = asMap(raw);
    if (root == null) return null;
    final nested = asMap(root['data']);
    return nested ?? root;
  }

  List<Map<String, dynamic>> _extractListPayload(dynamic raw) {
    final root = asMap(raw);
    if (root == null) {
      return asList(raw, (e) => asMap(e) ?? <String, dynamic>{}) ?? [];
    }

    if (root['results'] != null) {
      return asList(root['results'], (e) => asMap(e) ?? <String, dynamic>{}) ?? [];
    }

    final nested = root['data'];
    final nestedMap = asMap(nested);
    if (nestedMap != null && nestedMap['results'] != null) {
      return asList(nestedMap['results'], (e) => asMap(e) ?? <String, dynamic>{}) ?? [];
    }

    return asList(nested, (e) => asMap(e) ?? <String, dynamic>{}) ?? [];
  }

  Future<DashboardStats> fetchStats({int? academyId}) async {
    try {
      final Map<String, dynamic> query = {};
      if (academyId != null) query['academy_id'] = academyId;

      final res = await apiClient.dio.get(ApiEndpoints.analyticsStats, queryParameters: query);
      final data = _extractMapPayload(res.data);
      if (data == null) throw Exception('بيانات الإحصائيات غير صالحة');
      return DashboardStats.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل إحصائيات لوحة القيادة');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMonthlyGrowth() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.analyticsMonthlyGrowth);
      return _extractListPayload(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل نمو اللاعبين الشهري');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDepartmentDistribution() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.analyticsDepartmentDistribution);
      return _extractListPayload(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل توزيع اللاعبين على الأكاديميات');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRevenue() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.analyticsRevenue);
      return _extractListPayload(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل تقرير الإيرادات');
    }
  }
}
