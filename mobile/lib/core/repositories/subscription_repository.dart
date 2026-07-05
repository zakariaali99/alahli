import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/subscription_model.dart';
import '../models/paginated_response.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';
import '../helpers/api_error_parser.dart';
import '../models/app_api_exception.dart';

AppApiException _appEx(String msg) => AppApiException(message: msg);

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
      throw dioToAppApiException(e, fallback: 'فشل تحميل الاشتراكات');
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
      if (data == null) throw _appEx('بيانات الاشتراك غير صالحة');
      return SubscriptionModel.fromJson(data);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل تحميل تفاصيل الاشتراك');
    }
  }

  Future<SubscriptionModel> updateSubscriptionStatus(int id, String status, {String? rejectionReason}) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        data['rejection_reason'] = rejectionReason;
      }
      final res = await apiClient.dio.patch(
        '${ApiEndpoints.subscriptions}$id/',
        data: data,
      );
      final resData = asMap(res.data);
      if (resData == null) throw _appEx('فشل تحديث حالة الاشتراك');
      return SubscriptionModel.fromJson(resData);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل معالجة الطلب');
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
      if (data == null) throw _appEx('فشل تجديد الاشتراك');
      return SubscriptionModel.fromJson(data);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل تجديد الاشتراك');
    }
  }

  Future<SubscriptionModel> createSubscription(dynamic data) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.subscriptions, data: data);
      final resData = asMap(res.data);
      if (resData == null) throw _appEx('فشل إنشاء الاشتراك');
      return SubscriptionModel.fromJson(resData);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل إنشاء الاشتراك');
    }
  }
}
