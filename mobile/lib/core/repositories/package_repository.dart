import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/package_model.dart';

class PackageRepository {
  final ApiClient _client;

  PackageRepository(this._client);

  Future<List<PackageModel>> getPackages() async {
    final res = await _client.dio.get('/packages/');
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? PackageModel.fromJson(m) : null;
        })
        .whereType<PackageModel>()
        .toList();
  }
}
