import 'package:flutter/material.dart';

String safeInitials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

Color safeColor(String? hexColor, [Color fallback = const Color(0xFF4183D9)]) {
  if (hexColor == null || hexColor.isEmpty) return fallback;
  try {
    String hex = hexColor;
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
  } catch (_) {}
  return fallback;
}

DateTime? safeDateTimeParse(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  try {
    return DateTime.parse(dateStr);
  } catch (_) {
    return null;
  }
}
