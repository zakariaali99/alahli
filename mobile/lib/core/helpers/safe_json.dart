Map<String, dynamic>? asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  return null;
}

List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  return [];
}

String asString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  return fallback;
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}
