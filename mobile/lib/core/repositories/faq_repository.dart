import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/faq_model.dart';

class FaqRepository {
  final ApiClient _client;

  FaqRepository(this._client);

  Future<List<FaqModel>> getFaqs() async {
    final res = await _client.dio.get('/faqs/');
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? FaqModel.fromJson(m) : null;
        })
        .whereType<FaqModel>()
        .toList();
  }
}
