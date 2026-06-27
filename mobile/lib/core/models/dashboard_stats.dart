class DashboardStats {
  final int totalAthletes;
  final int activeMemberships;
  final int expiredMemberships;
  final int expiringSoon;
  final int newThisMonth;
  final double totalRevenue;
  final int renewalRate;

  const DashboardStats({
    required this.totalAthletes,
    required this.activeMemberships,
    required this.expiredMemberships,
    required this.expiringSoon,
    required this.newThisMonth,
    required this.totalRevenue,
    required this.renewalRate,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalAthletes: json['total_athletes'] as int? ?? 0,
    activeMemberships: json['active_memberships'] as int? ?? 0,
    expiredMemberships: json['expired_memberships'] as int? ?? 0,
    expiringSoon: json['expiring_soon'] as int? ?? 0,
    newThisMonth: json['new_this_month'] as int? ?? 0,
    totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
    renewalRate: json['renewal_rate'] as int? ?? 0,
  );
}

class MonthlyGrowth {
  final String month;
  final int count;

  const MonthlyGrowth({required this.month, required this.count});

  factory MonthlyGrowth.fromJson(Map<String, dynamic> json) => MonthlyGrowth(
    month: json['month'] as String? ?? '',
    count: json['count'] as int? ?? 0,
  );
}

class RevenueData {
  final String month;
  final double revenue;

  const RevenueData({required this.month, required this.revenue});

  factory RevenueData.fromJson(Map<String, dynamic> json) => RevenueData(
    month: json['month'] as String? ?? '',
    revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
  );
}

class DepartmentDist {
  final String departmentName;
  final int count;

  const DepartmentDist({required this.departmentName, required this.count});

  factory DepartmentDist.fromJson(Map<String, dynamic> json) => DepartmentDist(
    departmentName: json['department_name'] as String? ?? '',
    count: json['count'] as int? ?? 0,
  );
}
