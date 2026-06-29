import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/notification_model.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.notifications);
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }
      return asList(resultsList, (e) => NotificationModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل التنبيهات');
    }
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
