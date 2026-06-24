import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/trainer_model.dart';

class TrainerRepository {
  final ApiClient _client;

  TrainerRepository(this._client);

  Future<List<TrainerModel>> getTrainers() async {
    final res = await _client.dio.get('/trainers/');
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? TrainerModel.fromJson(m) : null;
        })
        .whereType<TrainerModel>()
        .toList();
  }

  Future<TrainerModel> getTrainer(int id) async {
    final res = await _client.dio.get('/trainers/$id/');
    return TrainerModel.fromJson(asMap(res.data)!);
  }
}
