import '../helpers/safe_json.dart';

class DashboardStats {
  final int totalAthletes;
  final int activeMemberships;
  final int expiredMemberships;
  final int expiringSoon;
  final int newThisMonth;
  final double totalRevenue;
  final int renewalRate;

  DashboardStats({
    required this.totalAthletes,
    required this.activeMemberships,
    required this.expiredMemberships,
    required this.expiringSoon,
    required this.newThisMonth,
    required this.totalRevenue,
    required this.renewalRate,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAthletes: asInt(json['total_athletes']) ?? 0,
      activeMemberships: asInt(json['active_memberships']) ?? 0,
      expiredMemberships: asInt(json['expired_memberships']) ?? 0,
      expiringSoon: asInt(json['expiring_soon']) ?? 0,
      newThisMonth: asInt(json['new_this_month']) ?? 0,
      totalRevenue: asDouble(json['total_revenue']) ?? 0.0,
      renewalRate: asInt(json['renewal_rate']) ?? 0,
    );
  }
}
