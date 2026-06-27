import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository(this._client);

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _client.dio.get('/notifications/');
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? NotificationModel.fromJson(m) : null;
        })
        .whereType<NotificationModel>()
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await _client.dio.patch('/notifications/$id/', data: {'is_read': true});
  }

  Future<void> markAllAsRead() async {
    await _client.dio.post('/notifications/mark_all_read/');
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/notifications/$id/');
  }

  Future<Map<String, dynamic>> sendNotification({required String title, required String body}) async {
    final res = await _client.dio.post('/notifications/', data: {'title': title, 'body': body});
    final data = asMap(res.data);
    if (data == null) throw Exception('فشل إرسال الإشعار');
    return data;
  }
}
