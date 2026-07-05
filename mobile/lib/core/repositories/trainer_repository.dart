import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/trainer_model.dart';
import '../models/group_model.dart';
import '../constants/api_endpoints.dart';
import '../helpers/safe_json.dart';
import '../helpers/api_error_parser.dart';
import '../models/app_api_exception.dart';

class TrainerRepository {
  final ApiClient apiClient;

  TrainerRepository({required this.apiClient});

  List<dynamic> _extractListPayload(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      if (raw['results'] is List) return raw['results'] as List<dynamic>;
      if (raw['data'] is List) return raw['data'] as List<dynamic>;
      if (raw['data'] is Map && raw['data']['results'] is List) {
        return raw['data']['results'] as List<dynamic>;
      }
    }
    return const [];
  }

  Future<List<TrainerModel>> fetchTrainers() async {
    try {
      final res = await apiClient.dio.get(
        ApiEndpoints.users,
        queryParameters: {'role': 'trainer'},
      );
      final resultsList = _extractListPayload(res.data);
      return asList(resultsList, (e) => TrainerModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل تحميل المدربين');
    }
  }

  Future<List<GroupModel>> fetchTrainerGroups(int coachId) async {
    try {
      final res = await apiClient.dio.get(
        ApiEndpoints.groups,
        queryParameters: {'coach': coachId},
      );
      final resultsList = _extractListPayload(res.data);
      return asList(resultsList, (e) => GroupModel.fromJson(asMap(e) ?? {})) ?? [];
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل تحميل مجموعات المدرب');
    }
  }

  Future<TrainerModel> createTrainer(dynamic data) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.users, data: data);
      final resData = asMap(res.data);
      if (resData == null) throw AppApiException(message: 'فشل إنشاء المدرب');
      return TrainerModel.fromJson(resData);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل إضافة مدرب جديد');
    }
  }

  Future<TrainerModel> updateTrainer(int id, dynamic data) async {
    try {
      final res = await apiClient.dio.patch('${ApiEndpoints.users}$id/', data: data);
      final resData = asMap(res.data);
      if (resData == null) throw AppApiException(message: 'فشل تعديل المدرب');
      return TrainerModel.fromJson(resData);
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل تعديل المدرب');
    }
  }

  Future<void> deleteTrainer(int id) async {
    try {
      await apiClient.dio.delete('${ApiEndpoints.users}$id/');
    } on DioException catch (e) {
      throw dioToAppApiException(e, fallback: 'فشل حذف المدرب');
    }
  }
}
