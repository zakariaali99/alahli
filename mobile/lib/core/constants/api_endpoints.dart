class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.22.95.35:8000/api',
  );

  // Auth
  static const String login = '/auth/login/';
  static const String logout = '/auth/logout/';
  static const String me = '/auth/me/';
  static const String changePassword = '/auth/change-password/';
  static const String users = '/auth/users/';

  // Athletes
  static const String athletes = '/athletes/';
  static String verifyAthlete(String membershipNumber) => '/athletes/verify/$membershipNumber/';
  static const String registrations = '/athletes/registrations/';
  static String createAthleteProfile(int id) => '/athletes/registrations/$id/create-athlete/';
  static String approveRegistration(int id) => '/athletes/registrations/$id/approve/';
  static String rejectRegistration(int id) => '/athletes/registrations/$id/reject/';

  // Subscriptions
  static const String subscriptions = '/subscriptions/';
  static String renewSubscription(int id) => '/subscriptions/$id/renew/';
  static const String bankDetails = '/subscriptions/bank_details/';

  // Departments/Academies
  static const String departments = '/departments/';
  static const String sports = '/sports/';
  static const String groups = '/groups/';

  // Trainers
  static const String trainers = '/trainers/';

  // Packages
  static const String packages = '/packages/';

  // Attendance
  static const String attendance = '/attendance/';

  // Analytics
  static const String analyticsStats = '/analytics/stats/';
  static const String analyticsMonthlyGrowth = '/analytics/monthly-growth/';
  static const String analyticsDepartmentDistribution = '/analytics/department-distribution/';
  static const String analyticsRevenue = '/analytics/revenue/';

  // Notifications
  static const String notifications = '/notifications/';
  static const String devices = '/notifications/devices/';
}
