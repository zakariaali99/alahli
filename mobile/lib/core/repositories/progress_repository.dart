import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/progress_model.dart';

class ProgressRepository {
  final ApiClient _client;

  ProgressRepository(this._client);

  Future<WeeklyProgressSummary> getWeeklyProgress({String? week}) async {
    final params = <String, dynamic>{};
    if (week != null) params['week'] = week;
    final res = await _client.dio.get('/progress/weekly/', queryParameters: params);
    return WeeklyProgressSummary.fromJson(asMap(res.data)!);
  }

  Future<List<AchievementModel>> getAchievements() async {
    final res = await _client.dio.get('/progress/achievements/');
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? AchievementModel.fromJson(m) : null;
        })
        .whereType<AchievementModel>()
        .toList();
  }
}
