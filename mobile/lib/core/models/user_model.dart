import '../helpers/safe_json.dart';

class AthleteDetail {
  final int id;
  final String phone;
  final String fullName;
  final String? membershipNumber;
  final String? departmentName;
  final String? photo;

  AthleteDetail({
    required this.id,
    required this.phone,
    required this.fullName,
    this.membershipNumber,
    this.departmentName,
    this.photo,
  });

  factory AthleteDetail.fromJson(Map<String, dynamic> json) {
    return AthleteDetail(
      id: asInt(json['id']) ?? 0,
      phone: asString(json['phone']) ?? '',
      fullName: asString(json['full_name']) ?? '',
      membershipNumber: asString(json['membership_number']),
      departmentName: asString(json['department_name']),
      photo: asString(json['photo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'full_name': fullName,
      'membership_number': membershipNumber,
      'department_name': departmentName,
      'photo': photo,
    };
  }
}

class UserModel {
  final int id;
  final String phone;
  final String firstNameAr;
  final String lastNameAr;
  final String fullNameAr;
  final String role;
  final bool isActive;
  final String? photo;
  final int? academy;
  final String? academyName;
  final AthleteDetail? athleteDetail;

  UserModel({
    required this.id,
    required this.phone,
    required this.firstNameAr,
    required this.lastNameAr,
    required this.fullNameAr,
    required this.role,
    required this.isActive,
    this.photo,
    this.academy,
    this.academyName,
    this.athleteDetail,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: asInt(json['id']) ?? 0,
      phone: asString(json['phone']) ?? '',
      firstNameAr: asString(json['first_name_ar']) ?? '',
      lastNameAr: asString(json['last_name_ar']) ?? '',
      fullNameAr: asString(json['full_name_ar']) ?? '',
      role: asString(json['role']) ?? '',
      isActive: asBool(json['is_active']) ?? false,
      photo: asString(json['photo']),
      academy: asInt(json['academy']),
      academyName: asString(json['academy_name']),
      athleteDetail: json['athlete_detail'] != null
          ? AthleteDetail.fromJson(json['athlete_detail'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'first_name_ar': firstNameAr,
      'last_name_ar': lastNameAr,
      'full_name_ar': fullNameAr,
      'role': role,
      'is_active': isActive,
      'photo': photo,
      'academy': academy,
      'academy_name': academyName,
      'athlete_detail': athleteDetail?.toJson(),
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isReception => role == 'reception';
  bool get isAcademyManager => role == 'academy_manager';
}
