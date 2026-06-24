class MembershipModel {
  final int id;
  final String athleteName;
  final String membershipNumber;
  final String departmentName;
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
    required this.departmentName,
    required this.packageName,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? '';
    final rawAmount = json['amount'];
    final parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0;
    return MembershipModel(
      id: json['id'] as int,
      athleteName: json['athlete_name'] as String? ?? '',
      membershipNumber: json['membership_number'] as String? ?? '',
      departmentName: json['department_name'] as String? ?? '',
      packageName: json['package_name'] as String? ?? '',
      amount: parsedAmount,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      isActive: rawStatus == 'active',
      status: rawStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'athlete_name': athleteName,
        'membership_number': membershipNumber,
        'department_name': departmentName,
        'package_name': packageName,
        'amount': amount,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
      };
}
