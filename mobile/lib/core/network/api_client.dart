import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  String? _accessToken;
  String? _refreshToken;
  void Function()? _onUnauthorized;

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
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 && _refreshToken != null) {
            try {
              final res = await Dio(
                BaseOptions(baseUrl: dio.options.baseUrl),
              ).post(
                '/auth/token/refresh/',
                data: {'refresh': _refreshToken},
              );
              _accessToken = res.data['access'] as String;
              error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              _onUnauthorized?.call();
              return handler.next(error);
            }
          }
          _onUnauthorized?.call();
          return handler.next(error);
        },
      ),
    );
  }

  void setTokens({String? access, String? refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void setOnUnauthorized(void Function() callback) {
    _onUnauthorized = callback;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  bool get isAuthenticated => _accessToken != null;
}


