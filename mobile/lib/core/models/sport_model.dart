import '../helpers/safe_json.dart';

class SportModel {
  final int id;
  final String name;
  final String nameAr;
  final int department;
  final String departmentName;
  final bool isActive;

  SportModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.department,
    required this.departmentName,
    required this.isActive,
  });

  factory SportModel.fromJson(Map<String, dynamic> json) {
    return SportModel(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      nameAr: asString(json['name_ar']) ?? '',
      department: asInt(json['department']) ?? 0,
      departmentName: asString(json['department_name']) ?? '',
      isActive: asBool(json['is_active']) ?? false,
    );
  }
}
