import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/subscription_model.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class SubscriptionRepository {
  final ApiClient apiClient;

  SubscriptionRepository({required this.apiClient});

  Future<List<SubscriptionModel>> fetchSubscriptions({
    String? status,
    String? search,
    int? athleteId,
  }) async {
    try {
      final Map<String, dynamic> query = {};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (athleteId != null) query['athlete'] = athleteId;

      final res = await apiClient.dio.get(ApiEndpoints.subscriptions, queryParameters: query);
      
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }

      final list = asList(resultsList, (e) => SubscriptionModel.fromJson(asMap(e) ?? {})) ?? [];
      return list;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل الاشتراكات');
    }
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
}
