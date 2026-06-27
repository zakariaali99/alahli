import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final ApiClient _client;

  ReviewRepository(this._client);

  Future<List<ReviewModel>> getReviews({int? trainerId}) async {
    final params = <String, dynamic>{};
    if (trainerId != null) params['trainer'] = trainerId;
    final res = await _client.dio.get('/trainers/reviews/', queryParameters: params);
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? ReviewModel.fromJson(m) : null;
        })
        .whereType<ReviewModel>()
        .toList();
  }

  Future<ReviewModel> createReview({
    required int trainer,
    required int rating,
    String comment = '',
  }) async {
    final res = await _client.dio.post('/trainers/reviews/', data: {
      'trainer': trainer,
      'rating': rating,
      'comment': comment,
    });
    return ReviewModel.fromJson(asMap(res.data)!);
  }
}
