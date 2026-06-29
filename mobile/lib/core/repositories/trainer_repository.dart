import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/trainer_model.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';

class TrainerRepository {
  final ApiClient apiClient;

  TrainerRepository({required this.apiClient});

  Future<List<TrainerModel>> fetchTrainers() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.trainers);
      dynamic resultsList = res.data;
      if (res.data is Map && res.data['results'] != null) {
        resultsList = res.data['results'];
      }
      return asList(resultsList, (e) => TrainerModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تحميل المدربين');
    }
  }

  Future<TrainerModel> createTrainer(Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.trainers, data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل إنشاء المدرب');
      return TrainerModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل إضافة مدرب جديد');
    }
  }

  Future<TrainerModel> updateTrainer(int id, Map<String, dynamic> data) async {
    try {
      final res = await apiClient.dio.patch('${ApiEndpoints.trainers}$id/', data: data);
      final resData = asMap(res.data);
      if (resData == null) throw Exception('فشل تعديل المدرب');
      return TrainerModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل تعديل المدرب');
    }
  }

  Future<void> deleteTrainer(int id) async {
    try {
      await apiClient.dio.delete('${ApiEndpoints.trainers}$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'فشل حذف المدرب');
    }
  }
}
