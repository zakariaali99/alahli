class DailyStatModel {
  final String dayAbbr;
  final String dayFull;
  final double value;
  final double hours;

  const DailyStatModel({
    required this.dayAbbr,
    required this.dayFull,
    required this.value,
    required this.hours,
  });

  factory DailyStatModel.fromJson(Map<String, dynamic> json) => DailyStatModel(
        dayAbbr: json['day_abbr'] as String? ?? '',
        dayFull: json['day_full'] as String? ?? '',
        value: (json['value'] as num?)?.toDouble() ?? 0,
        hours: (json['hours'] as num?)?.toDouble() ?? 0,
      );
}

class WeeklyProgressModel {
  final int id;
  final String weekStart;
  final int sessionsCount;
  final int activeMinutes;
  final double goalProgress;
  final int goalTarget;
  final List<DailyStatModel> dailyStats;

  const WeeklyProgressModel({
    required this.id,
    required this.weekStart,
    required this.sessionsCount,
    required this.activeMinutes,
    required this.goalProgress,
    required this.goalTarget,
    required this.dailyStats,
  });

  factory WeeklyProgressModel.fromJson(Map<String, dynamic> json) =>
      WeeklyProgressModel(
        id: json['id'] as int,
        weekStart: json['week_start'] as String? ?? '',
        sessionsCount: json['sessions_count'] as int? ?? 0,
        activeMinutes: json['active_minutes'] as int? ?? 0,
        goalProgress: (json['goal_progress'] as num?)?.toDouble() ?? 0,
        goalTarget: json['goal_target'] as int? ?? 5,
        dailyStats: (json['daily_stats'] as List<dynamic>?)
                ?.map((e) =>
                    DailyStatModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class AchievementModel {
  final int id;
  final String icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isLocked;
  final String? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isLocked,
    this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        id: json['id'] as int,
        icon: json['icon'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        isCompleted: json['is_completed'] as bool? ?? false,
        isLocked: json['is_locked'] as bool? ?? true,
        unlockedAt: json['unlocked_at'] as String?,
      );
}

class WeeklyProgressSummary {
  final String weekStart;
  final int sessionsCount;
  final int activeMinutes;
  final double goalProgress;
  final int goalTarget;
  final List<DailyStatModel> dailyStats;
  final Map<String, dynamic> performance;

  const WeeklyProgressSummary({
    required this.weekStart,
    required this.sessionsCount,
    required this.activeMinutes,
    required this.goalProgress,
    required this.goalTarget,
    required this.dailyStats,
    required this.performance,
  });

  factory WeeklyProgressSummary.fromJson(Map<String, dynamic> json) =>
      WeeklyProgressSummary(
        weekStart: json['week_start'] as String? ?? '',
        sessionsCount: json['sessions_count'] as int? ?? 0,
        activeMinutes: json['active_minutes'] as int? ?? 0,
        goalProgress: (json['goal_progress'] as num?)?.toDouble() ?? 0,
        goalTarget: json['goal_target'] as int? ?? 5,
        dailyStats: (json['daily_stats'] as List<dynamic>?)
                ?.map((e) =>
                    DailyStatModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        performance: json['performance'] as Map<String, dynamic>? ?? {},
      );
}
