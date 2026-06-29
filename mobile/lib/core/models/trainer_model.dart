import '../helpers/safe_json.dart';

class TrainerModel {
  final int id;
  final String fullNameAr;
  final String initials;
  final String role;
  final String? bio;
  final double rating;
  final int reviewsCount;
  final int experienceYears;
  final String? profileImage;

  TrainerModel({
    required this.id,
    required this.fullNameAr,
    required this.initials,
    required this.role,
    this.bio,
    required this.rating,
    required this.reviewsCount,
    required this.experienceYears,
    this.profileImage,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    return TrainerModel(
      id: asInt(json['id']) ?? 0,
      fullNameAr: asString(json['full_name_ar']) ?? '',
      initials: asString(json['initials']) ?? '',
      role: asString(json['role']) ?? '',
      bio: asString(json['bio']),
      rating: asDouble(json['rating']) ?? 0.0,
      reviewsCount: asInt(json['reviews_count']) ?? 0,
      experienceYears: asInt(json['experience_years']) ?? 0,
      profileImage: asString(json['profile_image']),
    );
  }
}
