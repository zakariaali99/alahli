import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  String? _token;

  ApiClient({String baseUrl = 'http://localhost:8000/api'})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Add custom error parsing or logouts on 401
          return handler.next(error);
        },
      ),
    );
  }

  void setToken(String? token) {
    _token = token;
  }

  bool get isAuthenticated => _token != null;
}
