class WorkoutSessionModel {
  final int id;
  final String name;
  final int? category;
  final String categoryDisplay;
  final String date;
  final String time;
  final int durationMinutes;
  final String location;
  final int? trainer;
  final String trainerName;
  final String trainerInitials;
  final bool isCompleted;

  const WorkoutSessionModel({
    required this.id,
    required this.name,
    this.category,
    required this.categoryDisplay,
    required this.date,
    required this.time,
    required this.durationMinutes,
    required this.location,
    this.trainer,
    required this.trainerName,
    required this.trainerInitials,
    required this.isCompleted,
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) =>
      WorkoutSessionModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        category: json['category'] as int?,
        categoryDisplay: json['category_display'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        durationMinutes: json['duration_minutes'] as int? ?? 0,
        location: json['location'] as String? ?? '',
        trainer: json['trainer'] as int?,
        trainerName: json['trainer_name'] as String? ?? '',
        trainerInitials: json['trainer_initials'] as String? ?? '',
        isCompleted: json['is_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'category_display': categoryDisplay,
        'date': date,
        'time': time,
        'duration_minutes': durationMinutes,
        'location': location,
        'trainer': trainer,
        'trainer_name': trainerName,
        'trainer_initials': trainerInitials,
        'is_completed': isCompleted,
      };
}
