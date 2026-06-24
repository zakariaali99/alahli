import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/membership_model.dart';

class SubscriptionRepository {
  final ApiClient _client;

  SubscriptionRepository(this._client);

  Future<List<MembershipModel>> getSubscriptions({int page = 1, String? search}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null) params['search'] = search;
    final res = await _client.dio.get('/subscriptions/', queryParameters: params);
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? MembershipModel.fromJson(m) : null;
        })
        .whereType<MembershipModel>()
        .toList();
  }

  Future<MembershipModel?> getActiveSubscription() async {
    final res = await _client.dio.get('/subscriptions/', queryParameters: {
      'status': 'active',
      'page_size': 1,
    });
    final data = asMap(res.data);
    if (data == null) return null;
    final results = asList(data['results']);
    if (results.isEmpty) return null;
    final first = asMap(results.first);
    return first != null ? MembershipModel.fromJson(first) : null;
  }
}
