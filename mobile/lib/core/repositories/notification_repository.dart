import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/notification_model.dart';
import '../models/paginated_response.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  Future<PaginatedResponse<NotificationModel>> fetchNotificationsPaginated({int page = 1}) async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.notifications, queryParameters: {'page': page});
      final data = asMap(res.data);

      if (data != null && data['results'] != null) {
        return PaginatedResponse<NotificationModel>(
          results: asList(data['results'], (e) => NotificationModel.fromJson(asMap(e) ?? {})) ?? [],
          count: asInt(data['count']) ?? 0,
          next: asString(data['next']),
          previous: asString(data['previous']),
        );
      }

      final list = asList(res.data, (e) => NotificationModel.fromJson(asMap(e) ?? {})) ?? [];
      return PaginatedResponse<NotificationModel>(results: list, count: list.length);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل التنبيهات');
    }
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    return (await fetchNotificationsPaginated()).results;
  }

  Future<void> registerDeviceToken({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await apiClient.dio.post(
        ApiEndpoints.devices,
        data: {
          'fcm_token': fcmToken,
          'platform': platform,
        },
      );
    } catch (_) {
      // Best effort
    }
  }
}
