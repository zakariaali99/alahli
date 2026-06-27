class PreferenceModel {
  final int id;
  final int user;
  final bool notificationsEnabled;
  final bool smsEnabled;
  final bool emailEnabled;
  final String language;
  final String theme;

  const PreferenceModel({
    required this.id,
    required this.user,
    required this.notificationsEnabled,
    required this.smsEnabled,
    required this.emailEnabled,
    required this.language,
    required this.theme,
  });

  factory PreferenceModel.fromJson(Map<String, dynamic> json) =>
      PreferenceModel(
        id: json['id'] as int,
        user: json['user'] as int? ?? 0,
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        smsEnabled: json['sms_enabled'] as bool? ?? true,
        emailEnabled: json['email_enabled'] as bool? ?? false,
        language: json['language'] as String? ?? 'ar',
        theme: json['theme'] as String? ?? 'light',
      );

  Map<String, dynamic> toJson() => {
        'notifications_enabled': notificationsEnabled,
        'sms_enabled': smsEnabled,
        'email_enabled': emailEnabled,
        'language': language,
        'theme': theme,
      };
}
