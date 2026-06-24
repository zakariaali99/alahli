import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/product_model.dart';

class StoreRepository {
  final ApiClient _client;

  StoreRepository(this._client);

  Future<List<ProductModel>> getProducts({int? category}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    final res = await _client.dio.get('/store/products/', queryParameters: params);
    final data = asMap(res.data);
    if (data == null) return [];
    return asList(data['results'])
        .map((e) {
          final m = asMap(e);
          return m != null ? ProductModel.fromJson(m) : null;
        })
        .whereType<ProductModel>()
        .toList();
  }
}
