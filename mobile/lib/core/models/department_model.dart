import '../helpers/safe_json.dart';

class DepartmentModel {
  final int id;
  final String name;
  final String nameAr;
  final String color;
  final String? logo;
  final String bankAccountNumber;
  final String iban;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.color,
    this.logo,
    required this.bankAccountNumber,
    required this.iban,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      nameAr: asString(json['name_ar']) ?? '',
      color: asString(json['color']) ?? '#1487D4',
      logo: asString(json['logo']),
      bankAccountNumber: asString(json['bank_account_number']) ?? '',
      iban: asString(json['iban']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'color': color,
      'logo': logo,
      'bank_account_number': bankAccountNumber,
      'iban': iban,
    };
  }
}
