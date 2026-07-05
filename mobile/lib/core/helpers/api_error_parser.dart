import 'package:dio/dio.dart';
import '../models/app_api_exception.dart';

class ParsedApiError {
  final String message;
  final Map<String, List<String>> fieldErrors;

  ParsedApiError({required this.message, this.fieldErrors = const {}});
}

ParsedApiError parseApiError(dynamic error) {
  if (error is AppApiException) {
    return ParsedApiError(
      message: error.message,
      fieldErrors: error.fieldErrors,
    );
  }

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ParsedApiError(message: 'الخادم لا يستجيب. تحقق من اتصالك وحاول مرة أخرى.');
      case DioExceptionType.connectionError:
        return ParsedApiError(message: 'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.');
      case DioExceptionType.badResponse:
        return _parseBadResponse(error);
      case DioExceptionType.cancel:
        return ParsedApiError(message: 'تم إلغاء العملية.');
      default:
        return ParsedApiError(message: 'حدث خطأ غير متوقع. حاول مرة أخرى.');
    }
  }

  final msg = error.toString().replaceAll('Exception: ', '');
  return ParsedApiError(message: msg.isEmpty ? 'حدث خطأ غير متوقع' : msg);
}

ParsedApiError _parseBadResponse(DioException error) {
  final status = error.response?.statusCode;
  final body = error.response?.data;

  if (body is! Map) {
    return ParsedApiError(message: _statusFallback(status) ?? 'حدث خطأ غير متوقع.');
  }

  final Map<String, List<String>> fieldErrors = {};
  String? mainMessage;

  // 1. Backend custom handler: detail: { field: [msg] }
  final detail = body['detail'];
  if (detail is Map) {
    detail.forEach((key, value) {
      if (value is List) {
        fieldErrors[key.toString()] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        fieldErrors[key.toString()] = [value];
      }
    });
    mainMessage = fieldErrors.values.expand((e) => e).join('\n');
    if (mainMessage.isEmpty) mainMessage = null;
  }

  // 2. Simple detail string
  if (detail is String && detail.isNotEmpty) {
    mainMessage = detail;
  }

  // 3. DRF field-level errors: phone: ["msg"], non_field_errors: ["msg"]
  if (mainMessage == null) {
    final nonField = body['non_field_errors'];
    if (nonField is List && nonField.isNotEmpty) {
      mainMessage = nonField.join('\n');
    }
    for (final entry in body.entries) {
      final key = entry.key.toString();
      if (key == 'detail' || key == 'non_field_errors') continue;
      final val = entry.value;
      if (val is List && val.isNotEmpty) {
        fieldErrors[key] = val.map((e) => e.toString()).toList();
      } else if (val is String && val.isNotEmpty) {
        fieldErrors[key] = [val];
      }
    }
  }

  if (mainMessage != null) {
    return ParsedApiError(message: mainMessage, fieldErrors: fieldErrors);
  }

  if (status == 500) {
    return ParsedApiError(message: 'حدث خطأ في الخادم. حاول مرة أخرى لاحقاً.');
  }
  if (status == 403) {
    return ParsedApiError(message: 'ليس لديك صلاحية للقيام بهذه العملية.');
  }
  if (status == 404) {
    return ParsedApiError(message: 'العنصر المطلوب غير موجود.');
  }
  if (status == 429) {
    return ParsedApiError(message: 'لقد تجاوزت الحد المسموح من الطلبات.');
  }

  return ParsedApiError(message: _statusFallback(status) ?? 'حدث خطأ غير متوقع.');
}

String? _statusFallback(int? status) {
  if (status == null) return null;
  if (status >= 500) return 'حدث خطأ في الخادم. حاول مرة أخرى لاحقاً.';
  return null;
}

AppApiException dioToAppApiException(DioException e, {String? fallback}) {
  final parsed = parseApiError(e);
  return AppApiException(
    message: parsed.message.isNotEmpty ? parsed.message : (fallback ?? 'حدث خطأ غير متوقع'),
    fieldErrors: parsed.fieldErrors,
    statusCode: e.response?.statusCode,
  );
}
