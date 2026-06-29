import '../helpers/safe_json.dart';

class SportModel {
  final int id;
  final String name;
  final String nameAr;
  final int department;

  SportModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.department,
  });

  factory SportModel.fromJson(Map<String, dynamic> json) {
    return SportModel(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      nameAr: asString(json['name_ar']) ?? '',
      department: asInt(json['department']) ?? 0,
    );
  }
}
