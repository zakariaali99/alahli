import '../network/api_client.dart';
import '../models/membership_model.dart';

class SubscriptionRepository {
  final ApiClient _client;

  SubscriptionRepository(this._client);

  Future<List<MembershipModel>> getSubscriptions({int page = 1, String? search}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null) params['search'] = search;
    final res = await _client.dio.get('/subscriptions/', queryParameters: params);
    final data = res.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results
        .map((e) => MembershipModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MembershipModel?> getActiveSubscription() async {
    final res = await _client.dio.get('/subscriptions/', queryParameters: {
      'is_active': 'true',
      'page_size': 1,
    });
    final data = res.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    if (results.isEmpty) return null;
    return MembershipModel.fromJson(results.first as Map<String, dynamic>);
  }
}
