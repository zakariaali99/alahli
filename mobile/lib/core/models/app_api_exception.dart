class AppApiException implements Exception {
  final String message;
  final Map<String, List<String>> fieldErrors;
  final int? statusCode;

  AppApiException({
    required this.message,
    this.fieldErrors = const {},
    this.statusCode,
  });

  @override
  String toString() => message;
}
