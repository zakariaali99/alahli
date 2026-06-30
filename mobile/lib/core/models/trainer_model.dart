import '../helpers/safe_json.dart';

class TrainerModel {
  final int id;
  final String phone;
  final String firstNameAr;
  final String lastNameAr;
  final String fullNameAr;
  final String role;
  final bool isActive;
  final String? profileImage; // we map json['photo'] to profileImage for backward compatibility in mobile code

  TrainerModel({
    required this.id,
    required this.phone,
    required this.firstNameAr,
    required this.lastNameAr,
    required this.fullNameAr,
    required this.role,
    required this.isActive,
    this.profileImage,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    return TrainerModel(
      id: asInt(json['id']) ?? 0,
      phone: asString(json['phone']) ?? '',
      firstNameAr: asString(json['first_name_ar']) ?? '',
      lastNameAr: asString(json['last_name_ar']) ?? '',
      fullNameAr: asString(json['full_name_ar']) ?? '',
      role: asString(json['role']) ?? '',
      isActive: asBool(json['is_active']) ?? true,
      profileImage: asString(json['photo']),
    );
  }
}

