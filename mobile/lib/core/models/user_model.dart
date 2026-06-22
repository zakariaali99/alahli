class UserModel {
  final int id;
  final String phone;
  final String firstNameAr;
  final String lastNameAr;
  final String fullNameAr;
  final String role;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.phone,
    required this.firstNameAr,
    required this.lastNameAr,
    required this.fullNameAr,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        phone: json['phone'] as String,
        firstNameAr: json['first_name_ar'] as String? ?? '',
        lastNameAr: json['last_name_ar'] as String? ?? '',
        fullNameAr: json['full_name_ar'] as String? ?? '',
        role: json['role'] as String? ?? 'viewer',
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'first_name_ar': firstNameAr,
        'last_name_ar': lastNameAr,
        'full_name_ar': fullNameAr,
        'role': role,
        'is_active': isActive,
      };
}
