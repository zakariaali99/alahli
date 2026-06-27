import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/dashboard_stats.dart';

class AdminRepository {
  final ApiClient _client;

  AdminRepository(this._client);

  Future<DashboardStats> getDashboardStats() async {
    final res = await _client.dio.get('/analytics/stats/');
    final data = asMap(res.data);
    if (data == null) throw Exception('استجابة غير صالحة من الخادم');
    return DashboardStats.fromJson(data);
  }

  Future<List<MonthlyGrowth>> getMonthlyGrowth() async {
    final res = await _client.dio.get('/analytics/monthly-growth/');
    final list = asList(res.data);
    return list.map((e) {
      final m = asMap(e);
      return m != null ? MonthlyGrowth.fromJson(m) : null;
    }).whereType<MonthlyGrowth>().toList();
  }

  Future<List<RevenueData>> getRevenue() async {
    final res = await _client.dio.get('/analytics/revenue/');
    final list = asList(res.data);
    return list.map((e) {
      final m = asMap(e);
      return m != null ? RevenueData.fromJson(m) : null;
    }).whereType<RevenueData>().toList();
  }

  Future<List<DepartmentDist>> getDepartmentDistribution() async {
    final res = await _client.dio.get('/analytics/department-distribution/');
    final list = asList(res.data);
    return list.map((e) {
      final m = asMap(e);
      return m != null ? DepartmentDist.fromJson(m) : null;
    }).whereType<DepartmentDist>().toList();
  }

  Future<Map<String, dynamic>> getAthletes({int page = 1, int pageSize = 20, String? search}) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _client.dio.get('/athletes/', queryParameters: params);
    final data = asMap(res.data);
    if (data == null) throw Exception('استجابة غير صالحة من الخادم');
    return data;
  }

  Future<Map<String, dynamic>> createAthlete(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/athletes/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('استجابة غير صالحة من الخادم');
    return body;
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    final res = await _client.dio.get('/departments/');
    final data = asMap(res.data);
    final results = data != null ? asList(data['results']) : asList(res.data);
    return results.map((e) {
      final m = asMap(e);
      return m ?? <String, dynamic>{};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getNotifications({int page = 1, int pageSize = 20}) async {
    final res = await _client.dio.get('/notifications/', queryParameters: {'page': page, 'page_size': pageSize});
    final data = asMap(res.data);
    if (data == null) return [];
    final results = asList(data['results']);
    return results.map((e) {
      final m = asMap(e);
      return m ?? <String, dynamic>{};
    }).toList();
  }

  Future<void> sendNotification(Map<String, dynamic> data) async {
    await _client.dio.post('/notifications/', data: data);
  }

  Future<List<Map<String, dynamic>>> getExercises({int page = 1, int pageSize = 20}) async {
    final res = await _client.dio.get('/sessions/exercises/', queryParameters: {'page': page, 'page_size': pageSize});
    final data = asMap(res.data);
    if (data == null) return [];
    final results = asList(data['results']);
    return results.map((e) {
      final m = asMap(e);
      return m ?? <String, dynamic>{};
    }).toList();
  }

  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/sessions/exercises/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('فشل إنشاء التمرين');
    return body;
  }

  Future<void> deleteExercise(int id) async {
    await _client.dio.delete('/sessions/exercises/$id/');
  }

  Future<Map<String, dynamic>> updateAthlete(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.patch('/athletes/$id/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('استجابة غير صالحة');
    return body;
  }

  Future<Map<String, dynamic>> getAthleteDetail(int id) async {
    final res = await _client.dio.get('/athletes/$id/');
    final data = asMap(res.data);
    if (data == null) throw Exception('استجابة غير صالحة');
    return data;
  }

  Future<List<Map<String, dynamic>>> getPackages() async {
    final res = await _client.dio.get('/packages/');
    final data = asMap(res.data);
    if (data == null) return [];
    final results = asList(data['results']);
    return results.map((e) {
      final m = asMap(e);
      return m ?? <String, dynamic>{};
    }).toList();
  }

  Future<Map<String, dynamic>> createPackage(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/packages/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('فشل إنشاء الباقة');
    return body;
  }

  Future<Map<String, dynamic>> updatePackage(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.patch('/packages/$id/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('فشل تحديث الباقة');
    return body;
  }

  Future<void> deletePackage(int id) async {
    await _client.dio.delete('/packages/$id/');
  }

  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/departments/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('فشل إنشاء المجموعة');
    return body;
  }

  Future<Map<String, dynamic>> updateDepartment(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.patch('/departments/$id/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('فشل تحديث المجموعة');
    return body;
  }

  Future<void> deleteDepartment(int id) async {
    await _client.dio.delete('/departments/$id/');
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final res = await _client.dio.get('/sessions/sessions/');
    final data = asMap(res.data);
    if (data == null) return [];
    final results = asList(data['results']);
    return results.map((e) {
      final m = asMap(e);
      return m ?? <String, dynamic>{};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTrainers() async {
    final res = await _client.dio.get('/trainers/');
    final data = asMap(res.data);
    if (data == null) return [];
    final results = asList(data['results']);
    return results.map((e) {
      final m = asMap(e);
      return m ?? <String, dynamic>{};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getUsers({int page = 1, int pageSize = 20, String? search}) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _client.dio.get('/accounts/users/', queryParameters: params);
    final data = asMap(res.data);
    if (data == null) return [];
    final results = asList(data['results']);
    return results.map((e) {
      final m = asMap(e);
      return m ?? <String, dynamic>{};
    }).toList();
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/accounts/users/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('فشل إنشاء المستخدم');
    return body;
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.patch('/accounts/users/$id/', data: data);
    final body = asMap(res.data);
    if (body == null) throw Exception('فشل تحديث المستخدم');
    return body;
  }

  Future<void> deleteUser(int id) async {
    await _client.dio.delete('/accounts/users/$id/');
  }
}
