import '../helpers/safe_json.dart';

class AthleteModel {
  final int id;
  final String membershipNumber;
  final String fullName;
  final String phone;
  final String? parentPhone;
  final String? birthDate;
  final String gender;
  final int? department;
  final String? departmentName;
  final String? photo;
  final String? qrCode;
  final String? notes;
  final bool isActive;
  final String? createdAt;

  AthleteModel({
    required this.id,
    required this.membershipNumber,
    required this.fullName,
    required this.phone,
    this.parentPhone,
    this.birthDate,
    required this.gender,
    this.department,
    this.departmentName,
    this.photo,
    this.qrCode,
    this.notes,
    required this.isActive,
    this.createdAt,
  });

  factory AthleteModel.fromJson(Map<String, dynamic> json) {
    return AthleteModel(
      id: asInt(json['id']) ?? 0,
      membershipNumber: asString(json['membership_number']) ?? '',
      fullName: asString(json['full_name']) ?? '',
      phone: asString(json['phone']) ?? '',
      parentPhone: asString(json['parent_phone']),
      birthDate: asString(json['birth_date']),
      gender: asString(json['gender']) ?? 'male',
      department: asInt(json['department']),
      departmentName: asString(json['department_name']),
      photo: asString(json['photo']),
      qrCode: asString(json['qr_code']),
      notes: asString(json['notes']),
      isActive: asBool(json['is_active']) ?? false,
      createdAt: asString(json['created_at']),
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
    };
  }
}
