import '../helpers/safe_json.dart';

class PackageModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String durationType;
  final int durationValue;
  final int maxAthletes;
  final String tag;
  final List<String> features;
  final String iconName;
  final String colorClass;
  final bool isActive;
  final int? department;
  final int order;

  PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationType,
    required this.durationValue,
    required this.maxAthletes,
    required this.tag,
    required this.features,
    required this.iconName,
    required this.colorClass,
    required this.isActive,
    this.department,
    required this.order,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      description: asString(json['description']) ?? '',
      price: asDouble(json['price']) ?? 0.0,
      durationType: asString(json['duration_type']) ?? 'months',
      durationValue: asInt(json['duration_value']) ?? 1,
      maxAthletes: asInt(json['max_athletes']) ?? 1,
      tag: asString(json['tag']) ?? 'normal',
      features: asList(json['features'], (e) => e.toString()) ?? [],
      iconName: asString(json['icon_name']) ?? '',
      colorClass: asString(json['color_class']) ?? '',
      isActive: asBool(json['is_active']) ?? false,
      department: asInt(json['department']),
      order: asInt(json['order']) ?? 0,
    );
  }
}
