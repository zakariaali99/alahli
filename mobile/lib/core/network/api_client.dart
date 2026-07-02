import 'dart:async';

import 'package:dio/dio.dart';

import '../helpers/safe_json.dart';

const _maxRetries = 2;

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
    dio.interceptors.addAll([
      _retryInterceptor(),
      _authInterceptor(),
    ]);
  }

  InterceptorsWrapper _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_isRetryable(error)) {
          final retries = error.requestOptions.extra['retryCount'] as int? ?? 0;
          if (retries < _maxRetries) {
            final delay = Duration(seconds: (retries + 1) * 2);
            await Future.delayed(delay);
            final opts = error.requestOptions;
            opts.extra['retryCount'] = retries + 1;
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(e as DioException);
            }
          }
        }
        return handler.next(error);
      },
    );
  }

  bool _isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return status == 429 || status == 503;
      default:
        return false;
    }
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
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
    );
  }

  String errorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'الخادم لا يستجيب. تحقق من اتصالك وحاول مرة أخرى.';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final body = error.response?.data;
        if (body is Map) {
          final detail = body['detail'];
          if (detail is String && detail.isNotEmpty) return detail;
          final messages = body.values.whereType<String>().toList();
          if (messages.isNotEmpty) return messages.join('\n');
        }
        if (status == 500) return 'حدث خطأ في الخادم. حاول مرة أخرى لاحقاً.';
        if (status == 403) return 'ليس لديك صلاحية للقيام بهذه العملية.';
        if (status == 404) return 'العنصر المطلوب غير موجود.';
        if (status == 429) return 'لقد تجاوزت الحد المسموح من الطلبات. حاول لاحقاً.';
        return 'حدث خطأ غير متوقع.';
      case DioExceptionType.cancel:
        return 'تم إلغاء العملية.';
      default:
        return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    }
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
