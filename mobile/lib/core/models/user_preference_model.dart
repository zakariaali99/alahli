import '../helpers/safe_json.dart';

class UserPreferenceModel {
  final int id;
  final int user;
  final bool notificationsEnabled;
  final bool smsEnabled;
  final bool emailEnabled;
  final String language;
  final String theme;

  UserPreferenceModel({
    required this.id,
    required this.user,
    required this.notificationsEnabled,
    required this.smsEnabled,
    required this.emailEnabled,
    required this.language,
    required this.theme,
  });

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) {
    return UserPreferenceModel(
      id: asInt(json['id']) ?? 0,
      user: asInt(json['user']) ?? 0,
      notificationsEnabled: asBool(json['notifications_enabled']) ?? true,
      smsEnabled: asBool(json['sms_enabled']) ?? true,
      emailEnabled: asBool(json['email_enabled']) ?? true,
      language: asString(json['language']) ?? 'ar',
      theme: asString(json['theme']) ?? 'light',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'notifications_enabled': notificationsEnabled,
      'sms_enabled': smsEnabled,
      'email_enabled': emailEnabled,
      'language': language,
      'theme': theme,
    };
  }

  UserPreferenceModel copyWith({
    bool? notificationsEnabled,
    bool? smsEnabled,
    bool? emailEnabled,
    String? language,
    String? theme,
  }) {
    return UserPreferenceModel(
      id: id,
      user: user,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}
