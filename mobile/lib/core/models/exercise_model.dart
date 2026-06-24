class ExerciseMovementModel {
  final int id;
  final String name;
  final int sets;
  final int reps;
  final String imageUrl;
  final int order;

  const ExerciseMovementModel({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.imageUrl,
    required this.order,
  });

  factory ExerciseMovementModel.fromJson(Map<String, dynamic> json) =>
      ExerciseMovementModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        sets: json['sets'] as int? ?? 0,
        reps: json['reps'] as int? ?? 0,
        imageUrl: json['image_url'] as String? ?? '',
        order: json['order'] as int? ?? 0,
      );
}

class ExerciseEquipmentModel {
  final int id;
  final String name;

  const ExerciseEquipmentModel({required this.id, required this.name});

  factory ExerciseEquipmentModel.fromJson(Map<String, dynamic> json) =>
      ExerciseEquipmentModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
      );
}

class ExerciseModel {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final int calories;
  final int durationMinutes;
  final String difficulty;
  final List<ExerciseMovementModel> movements;
  final List<ExerciseEquipmentModel> equipment;

  const ExerciseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.calories,
    required this.durationMinutes,
    required this.difficulty,
    required this.movements,
    required this.equipment,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        calories: json['calories'] as int? ?? 0,
        durationMinutes: json['duration_minutes'] as int? ?? 0,
        difficulty: json['difficulty'] as String? ?? '',
        movements: (json['movements'] as List<dynamic>?)
                ?.map((e) =>
                    ExerciseMovementModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        equipment: (json['equipment'] as List<dynamic>?)
                ?.map((e) =>
                    ExerciseEquipmentModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
