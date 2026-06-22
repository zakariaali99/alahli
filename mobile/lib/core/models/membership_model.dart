class MembershipModel {
  final int id;
  final String athleteName;
  final String membershipNumber;
  final String department;
  final String packageName;
  final double amount;
  final String startDate;
  final String endDate;
  final bool isActive;
  final String status;

  const MembershipModel({
    required this.id,
    required this.athleteName,
    required this.membershipNumber,
    required this.department,
    required this.packageName,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) => MembershipModel(
        id: json['id'] as int,
        athleteName: json['athlete_name'] as String? ?? '',
        membershipNumber: json['membership_number'] as String? ?? '',
        department: json['department'] as String? ?? '',
        packageName: json['package_name'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? false,
        status: json['status'] as String? ?? 'غير معروف',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'athlete_name': athleteName,
        'membership_number': membershipNumber,
        'department': department,
        'package_name': packageName,
        'amount': amount,
        'start_date': startDate,
        'end_date': endDate,
        'is_active': isActive,
        'status': status,
      };
}
