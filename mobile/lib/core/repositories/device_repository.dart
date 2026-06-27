import 'package:dio/dio.dart';
import '../network/api_client.dart';

class DeviceRepository {
  final ApiClient _client;

  DeviceRepository(this._client);

  Future<void> registerToken(String fcmToken, String platform) async {
    try {
      await _client.dio.post('/notifications/devices/', data: {
        'fcm_token': fcmToken,
        'platform': platform,
      });
    } on DioException catch (_) {
      // Token registration is best-effort
    }
  }
}
