import '../helpers/safe_json.dart';

class AthleteDetail {
  final int id;
  final String phone;
  final String fullName;
  final String? membershipNumber;
  final String? departmentName;
  final String? photo;
  final String? residence;
  final String? healthStatus;

  AthleteDetail({
    required this.id,
    required this.phone,
    required this.fullName,
    this.membershipNumber,
    this.departmentName,
    this.photo,
    this.residence,
    this.healthStatus,
  });

  factory AthleteDetail.fromJson(Map<String, dynamic> json) {
    return AthleteDetail(
      id: asInt(json['id']) ?? 0,
      phone: asString(json['phone']) ?? '',
      fullName: asString(json['full_name']) ?? '',
      membershipNumber: asString(json['membership_number']),
      departmentName: asString(json['department_name']),
      photo: asString(json['photo']),
      residence: asString(json['residence']),
      healthStatus: asString(json['health_status']),
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
      'residence': residence,
      'health_status': healthStatus,
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
  final String? residence;
  final String? whatsappPhone;
  final int? academy;
  final String? academyName;
  final AthleteDetail? athleteDetail;
  final String? registrationStatus;
  final String? registrationRejectionReason;

  UserModel({
    required this.id,
    required this.phone,
    required this.firstNameAr,
    required this.lastNameAr,
    required this.fullNameAr,
    required this.role,
    required this.isActive,
    this.photo,
    this.residence,
    this.whatsappPhone,
    this.academy,
    this.academyName,
    this.athleteDetail,
    this.registrationStatus,
    this.registrationRejectionReason,
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
      residence: asString(json['residence']),
      whatsappPhone: asString(json['whatsapp_phone']),
      academy: asInt(json['academy']),
      academyName: asString(json['academy_name']),
      athleteDetail: json['athlete_detail'] != null
          ? AthleteDetail.fromJson(json['athlete_detail'])
          : null,
      registrationStatus: asString(json['registration_status']),
      registrationRejectionReason: asString(json['registration_rejection_reason']),
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
      'residence': residence,
      'whatsapp_phone': whatsappPhone,
      'academy': academy,
      'academy_name': academyName,
      'athlete_detail': athleteDetail?.toJson(),
      'registration_status': registrationStatus,
      'registration_rejection_reason': registrationRejectionReason,
    };
  }


  bool get isSuperAdmin => role == 'super_admin';
  bool get isReception => role == 'reception';
  bool get isAcademyManager => role == 'academy_manager';
  bool get isRejectedRegistration => registrationStatus == 'rejected' && !isActive;
}
