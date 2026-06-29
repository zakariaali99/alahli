import '../helpers/safe_json.dart';

class GroupModel {
  final int id;
  final String name;
  final String nameAr;
  final int sport;
  final int? coachId;
  final List<String> days;
  final String startTime;
  final String endTime;

  GroupModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.sport,
    this.coachId,
    required this.days,
    required this.startTime,
    required this.endTime,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      nameAr: asString(json['name_ar']) ?? '',
      sport: asInt(json['sport']) ?? 0,
      coachId: asInt(json['coach']),
      days: asList(json['days'], (e) => e.toString()) ?? [],
      startTime: asString(json['start_time']) ?? '',
      endTime: asString(json['end_time']) ?? '',
    );
  }
}
