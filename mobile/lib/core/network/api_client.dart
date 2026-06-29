import 'dart:async';
import 'package:dio/dio.dart';
import '../helpers/safe_json.dart';

class ApiClient {
  final Dio dio;
  String? _accessToken;
  String? _refreshToken;
  void Function()? _onUnauthorized;
  void Function(String access, String refresh)? _onTokensRefreshed;

  Completer<bool>? _refreshCompleter;

  ApiClient({required String baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
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
            final isRefreshRequest = error.requestOptions.path.contains('/auth/token/refresh/');
            if (!isRefreshRequest) {
              final success = await _refreshTokens();
              if (success && _accessToken != null) {
                try {
                  error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
                  final retryResponse = await dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                } catch (_) {
                  return handler.next(error);
                }
              } else {
                _onUnauthorized?.call();
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshTokens() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final res = await Dio(
        BaseOptions(baseUrl: dio.options.baseUrl),
      ).post(
        '/auth/token/refresh/',
        data: {'refresh': _refreshToken},
      );
      final refreshData = asMap(res.data);
      if (refreshData != null) {
        final newAccess = asString(refreshData['access']);
        final newRefresh = asString(refreshData['refresh']);

        if (newAccess != null) {
          _accessToken = newAccess;
          if (newRefresh != null) {
            _refreshToken = newRefresh;
          }
          if (_refreshToken != null) {
            _onTokensRefreshed?.call(_accessToken!, _refreshToken!);
          }
          _refreshCompleter!.complete(true);
          return true;
        }
      }
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
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
