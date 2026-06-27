class AnnouncementModel {
  final int id;
  final String title;
  final String body;
  final bool isActive;
  final String createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isActive,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) =>
      AnnouncementModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );
}
