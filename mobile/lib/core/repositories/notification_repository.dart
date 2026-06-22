import '../network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository(this._client);

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _client.dio.get('/notifications/');
    final data = res.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await _client.dio.patch('/notifications/$id/', data: {'is_read': true});
  }

  Future<void> markAllAsRead() async {
    await _client.dio.post('/notifications/mark-all-read/');
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/notifications/$id/');
  }
}
