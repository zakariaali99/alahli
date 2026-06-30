import '../helpers/safe_json.dart';

class GroupModel {
  final int id;
  final String name;
  final String nameAr;
  final int sport;
  final String sportName;
  final int? coachId;
  final String coachName;
  final List<String> days;
  final String startTime;
  final String endTime;
  final bool isActive;

  GroupModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.sport,
    required this.sportName,
    this.coachId,
    required this.coachName,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      nameAr: asString(json['name_ar']) ?? '',
      sport: asInt(json['sport']) ?? 0,
      sportName: asString(json['sport_name']) ?? '',
      coachId: asInt(json['coach']),
      coachName: asString(json['coach_name']) ?? '',
      days: asList(json['days'], (e) => e.toString()) ?? [],
      startTime: asString(json['start_time']) ?? '',
      endTime: asString(json['end_time']) ?? '',
      isActive: asBool(json['is_active']) ?? false,
    );
  }
}
