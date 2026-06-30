import '../helpers/safe_json.dart';

class RegistrationModel {
  final int id;
  final int userId;
  final String userName;
  final String userPhone;
  final String roleChoice;
  final String status;
  final int? reviewedBy;
  final String? reviewedAt;
  final String createdAt;
  final int? athleteId;
  final String? athleteName;
  final String? athletePhoto;
  final String? athleteMembershipNumber;
  final String? athleteDepartmentName;
  final bool hasParent;
  final String? parentName;
  final String? parentPhone;

  RegistrationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.roleChoice,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.athleteId,
    this.athleteName,
    this.athletePhoto,
    this.athleteMembershipNumber,
    this.athleteDepartmentName,
    this.hasParent = false,
    this.parentName,
    this.parentPhone,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: asInt(json['id']) ?? 0,
      userId: asInt(json['user']) ?? 0,
      userName: asString(json['user_name']) ?? '',
      userPhone: asString(json['user_phone']) ?? '',
      roleChoice: asString(json['role_choice']) ?? 'athlete',
      status: asString(json['status']) ?? 'pending',
      reviewedBy: asInt(json['reviewed_by']),
      reviewedAt: asString(json['reviewed_at']),
      createdAt: asString(json['created_at']) ?? '',
      athleteId: asInt(json['athlete_id']),
      athleteName: asString(json['athlete_name']),
      athletePhoto: asString(json['athlete_photo']),
      athleteMembershipNumber: asString(json['athlete_membership_number']),
      athleteDepartmentName: asString(json['athlete_department_name']),
      hasParent: asBool(json['has_parent']) ?? false,
      parentName: asString(json['parent_name']),
      parentPhone: asString(json['parent_phone']),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
