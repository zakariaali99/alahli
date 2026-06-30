import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/subscription_model.dart';
import '../models/paginated_response.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class SubscriptionRepository {
  final ApiClient apiClient;

  SubscriptionRepository({required this.apiClient});

  Future<PaginatedResponse<SubscriptionModel>> fetchSubscriptionsPaginated({
    String? status,
    String? search,
    int? athleteId,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> query = {'page': page};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (athleteId != null) query['athlete'] = athleteId;

      final res = await apiClient.dio.get(ApiEndpoints.subscriptions, queryParameters: query);
      final data = asMap(res.data);

      if (data != null && data['results'] != null) {
        return PaginatedResponse<SubscriptionModel>(
          results: asList(data['results'], (e) => SubscriptionModel.fromJson(asMap(e) ?? {})) ?? [],
          count: asInt(data['count']) ?? 0,
          next: asString(data['next']),
          previous: asString(data['previous']),
        );
      }

      final list = asList(res.data, (e) => SubscriptionModel.fromJson(asMap(e) ?? {})) ?? [];
      return PaginatedResponse<SubscriptionModel>(results: list, count: list.length);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل الاشتراكات');
    }
  }

  Future<List<SubscriptionModel>> fetchSubscriptions({
    String? status,
    String? search,
    int? athleteId,
  }) async {
    return (await fetchSubscriptionsPaginated(
      status: status,
      search: search,
      athleteId: athleteId,
    )).results;
  }

  Future<SubscriptionModel> fetchSubscription(int id) async {
    try {
      final res = await apiClient.dio.get('${ApiEndpoints.subscriptions}$id/');
      final data = asMap(res.data);
      if (data == null) throw Exception('بيانات الاشتراك غير صالحة');
      return SubscriptionModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل تفاصيل الاشتراك');
    }
  }

  Future<SubscriptionModel> updateSubscriptionStatus(int id, String status) async {
    try {
      final res = await apiClient.dio.patch(
        '${ApiEndpoints.subscriptions}$id/',
        data: {'status': status},
      );
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل تحديث حالة الاشتراك');
      return SubscriptionModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل معالجة الطلب');
    }
  }

  Future<SubscriptionModel> renewSubscription({
    required int id,
    required int months,
    required double amount,
  }) async {
    try {
      final res = await apiClient.dio.post(
        ApiEndpoints.renewSubscription(id),
        data: {
          'months': months,
          'amount': amount,
        },
      );
      final data = asMap(res.data);
      if (data == null) throw Exception('فشل تجديد الاشتراك');
      return SubscriptionModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تجديد الاشتراك');
    }
  }

  Future<SubscriptionModel> createSubscription(dynamic data) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.subscriptions, data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل إنشاء الاشتراك');
      return SubscriptionModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? e.response?.data?.toString() ?? 'فشل إنشاء الاشتراك');
    }
  }
}
