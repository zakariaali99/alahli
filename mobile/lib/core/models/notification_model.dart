import '../helpers/safe_json.dart';

class NotificationModel {
  final int id;
  final int? athleteId;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    this.athleteId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: asInt(json['id']) ?? 0,
      athleteId: asInt(json['athlete']),
      title: asString(json['title']) ?? '',
      body: asString(json['body']) ?? '',
      isRead: asBool(json['is_read']) ?? false,
      createdAt: asString(json['created_at']) ?? '',
    );
  }
}
