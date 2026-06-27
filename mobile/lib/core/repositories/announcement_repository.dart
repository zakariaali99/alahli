import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  final ApiClient _client;

  AnnouncementRepository(this._client);

  Future<List<AnnouncementModel>> getAnnouncements() async {
    final res = await _client.dio.get('/notifications/announcements/');
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? AnnouncementModel.fromJson(m) : null;
        })
        .whereType<AnnouncementModel>()
        .toList();
  }
}
