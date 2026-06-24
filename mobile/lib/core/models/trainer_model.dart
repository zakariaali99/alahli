class TrainerClassModel {
  final int id;
  final String title;
  final String intensity;
  final String description;
  final double price;
  final String priceDisplay;
  final String currency;
  final int durationMinutes;
  final String imageUrl;

  const TrainerClassModel({
    required this.id,
    required this.title,
    required this.intensity,
    required this.description,
    required this.price,
    required this.priceDisplay,
    required this.currency,
    required this.durationMinutes,
    required this.imageUrl,
  });

  factory TrainerClassModel.fromJson(Map<String, dynamic> json) =>
      TrainerClassModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        intensity: json['intensity'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        priceDisplay: json['price_display'] as String? ?? '',
        currency: json['currency'] as String? ?? 'LYD',
        durationMinutes: json['duration_minutes'] as int? ?? 0,
        imageUrl: json['image_url'] as String? ?? '',
      );
}

class TrainerModel {
  final int id;
  final String fullNameAr;
  final String initials;
  final String role;
  final String bio;
  final double rating;
  final int reviewsCount;
  final int experienceYears;
  final String profileImage;
  final List<TrainerClassModel> classes;

  const TrainerModel({
    required this.id,
    required this.fullNameAr,
    required this.initials,
    required this.role,
    required this.bio,
    required this.rating,
    required this.reviewsCount,
    required this.experienceYears,
    required this.profileImage,
    required this.classes,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) => TrainerModel(
        id: json['id'] as int,
        fullNameAr: json['full_name_ar'] as String? ?? '',
        initials: json['initials'] as String? ?? '',
        role: json['role'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewsCount: json['reviews_count'] as int? ?? 0,
        experienceYears: json['experience_years'] as int? ?? 0,
        profileImage: json['profile_image'] as String? ?? '',
        classes: (json['classes'] as List<dynamic>?)
                ?.map((e) =>
                    TrainerClassModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
