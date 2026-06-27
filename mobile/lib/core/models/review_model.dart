class ReviewModel {
  final int id;
  final int athlete;
  final int trainer;
  final int rating;
  final String comment;
  final String createdAt;

  const ReviewModel({
    required this.id,
    required this.athlete,
    required this.trainer,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as int,
        athlete: json['athlete'] as int? ?? 0,
        trainer: json['trainer'] as int? ?? 0,
        rating: json['rating'] as int? ?? 0,
        comment: json['comment'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}
