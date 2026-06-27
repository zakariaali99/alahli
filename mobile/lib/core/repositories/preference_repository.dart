import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/preference_model.dart';

class PreferenceRepository {
  final ApiClient _client;

  PreferenceRepository(this._client);

  Future<PreferenceModel> getPreferences() async {
    final res = await _client.dio.get('/preferences/');
    return PreferenceModel.fromJson(asMap(res.data)!);
  }

  Future<PreferenceModel> updatePreferences(PreferenceModel prefs) async {
    final res = await _client.dio.patch('/preferences/', data: prefs.toJson());
    return PreferenceModel.fromJson(asMap(res.data)!);
  }
}
