import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/workout_session_model.dart';
import '../models/exercise_model.dart';

class WorkoutRepository {
  final ApiClient _client;

  WorkoutRepository(this._client);

  Future<List<WorkoutSessionModel>> getSessions({String? date, int? category}) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    if (category != null) params['category'] = category;
    final res = await _client.dio.get('/sessions/', queryParameters: params);
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? WorkoutSessionModel.fromJson(m) : null;
        })
        .whereType<WorkoutSessionModel>()
        .toList();
  }

  Future<ExerciseModel> getExercise(int id) async {
    final res = await _client.dio.get('/sessions/exercises/$id/');
    return ExerciseModel.fromJson(asMap(res.data)!);
  }
}
