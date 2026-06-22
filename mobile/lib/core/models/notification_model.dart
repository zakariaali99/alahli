class NotificationModel {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'is_read': isRead,
        'created_at': createdAt,
      };
}
