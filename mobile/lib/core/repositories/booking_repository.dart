import '../helpers/safe_json.dart';
import '../network/api_client.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final ApiClient _client;

  BookingRepository(this._client);

  Future<BookingModel> createBooking({
    required int sessionId,
    required String date,
    required String time,
  }) async {
    final res = await _client.dio.post('/sessions/bookings/', data: {
      'workout_session': sessionId,
      'date': date,
      'time': time,
    });
    final data = asMap(res.data);
    if (data == null) throw Exception('استجابة غير صالحة من الخادم');
    return BookingModel.fromJson(data);
  }

  Future<BookingModel> getBooking(int id) async {
    final res = await _client.dio.get('/sessions/bookings/$id/');
    final data = asMap(res.data);
    if (data == null) throw Exception('استجابة غير صالحة من الخادم');
    return BookingModel.fromJson(data);
  }
}
