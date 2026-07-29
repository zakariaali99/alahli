import '../helpers/safe_json.dart';

class AthleteModel {
  final int id;
  final String membershipNumber;
  final String fullName;
  final String phone;
  final String? parentName;
  final String? parentPhone;
  final String? residence;
  final String? healthStatus;
  final String? birthDate;
  final String gender;
  final int? department;
  final String? departmentName;
  final String? photo;
  final String? qrCode;
  final String? notes;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final int? registrationId;

  AthleteModel({
    required this.id,
    required this.membershipNumber,
    required this.fullName,
    required this.phone,
    this.parentName,
    this.parentPhone,
    this.residence,
    this.healthStatus,
    this.birthDate,
    required this.gender,
    this.department,
    this.departmentName,
    this.photo,
    this.qrCode,
    this.notes,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.registrationId,
  });

  factory AthleteModel.fromJson(Map<String, dynamic> json) {
    return AthleteModel(
      id: asInt(json['id']) ?? 0,
      membershipNumber: asString(json['membership_number']) ?? '',
      fullName: asString(json['full_name']) ?? '',
      phone: asString(json['phone']) ?? '',
      parentName: asString(json['parent_name']),
      parentPhone: asString(json['parent_phone']),
      residence: asString(json['residence']),
      healthStatus: asString(json['health_status']),
      birthDate: asString(json['birth_date']),
      gender: asString(json['gender']) ?? 'male',
      department: asInt(json['department']),
      departmentName: asString(json['department_name']),
      photo: asString(json['photo']),
      qrCode: asString(json['qr_code']),
      notes: asString(json['notes']),
      isActive: asBool(json['is_active']) ?? false,
      createdAt: asString(json['created_at']),
      updatedAt: asString(json['updated_at']),
      registrationId: asInt(json['registration']),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'membership_number': membershipNumber,
      'full_name': fullName,
      'phone': phone,
      'parent_phone': parentPhone,
      'birth_date': birthDate,
      'gender': gender,
      'department': department,
      'department_name': departmentName,
      'photo': photo,
      'qr_code': qrCode,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'registration': registrationId,
    };
  }
}
