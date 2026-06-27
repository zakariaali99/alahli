import 'package:dio/dio.dart';
import '../helpers/safe_json.dart';

class ApiClient {
  final Dio dio;
  String? _accessToken;
  String? _refreshToken;
  void Function()? _onUnauthorized;
  void Function(String access, String refresh)? _onTokensRefreshed;

  ApiClient({required String baseUrl})
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
              final refreshData = asMap(res.data);
              if (refreshData != null) {
                _accessToken = asString(refreshData['access']);
                _refreshToken = asString(refreshData['refresh']);
                _onTokensRefreshed?.call(_accessToken!, _refreshToken!);
              }
              error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              _onUnauthorized?.call();
              return handler.next(error);
            }
          }
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

  void setOnTokensRefreshed(void Function(String access, String refresh) callback) {
    _onTokensRefreshed = callback;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  bool get isAuthenticated => _accessToken != null;
}


