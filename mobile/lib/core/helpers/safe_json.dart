String? asString(dynamic val) {
  if (val == null) return null;
  return val.toString();
}

int? asInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) {
    return int.tryParse(val);
  }
  return null;
}

double? asDouble(dynamic val) {
  if (val == null) return null;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) {
    return double.tryParse(val);
  }
  return null;
}

bool? asBool(dynamic val) {
  if (val == null) return null;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) {
    final lower = val.toLowerCase();
    return lower == 'true' || lower == '1';
  }
  return null;
}

List<T>? asList<T>(dynamic val, T Function(dynamic) mapper) {
  if (val == null || val is! List) return null;
  return val.map((e) => mapper(e)).toList();
}

Map<String, dynamic>? asMap(dynamic val) {
  if (val == null || val is! Map) return null;
  return Map<String, dynamic>.from(val);
}
