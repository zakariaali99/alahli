import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/models/progress_model.dart';

class ProgressTrackingScreen extends ConsumerWidget {
  const ProgressTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(weeklyProgressProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقدمي', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: progressAsync.when(
        data: (progress) => _buildContent(theme, progress, achievementsAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError(theme),
      ),
    );
  }

  Widget _buildContent(
      ThemeData theme, WeeklyProgressSummary progress, AsyncValue<List<AchievementModel>> achievementsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPerformanceBanner(theme, progress),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMetricCard(theme, '${progress.sessionsCount}', 'جلسات تدريب', Icons.fitness_center)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard(theme, '${progress.activeMinutes}', 'دقيقة نشاط', Icons.timer_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          _buildWeeklyGoal(theme, progress),
          const SizedBox(height: 24),
          _buildBarChart(theme, progress),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: Text('الإنجازات', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          achievementsAsync.when(
            data: (achievements) => Column(
              children: achievements.map((a) => _buildAchievementCard(theme, a)).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => Text('تعذر تحميل الإنجازات', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBanner(ThemeData theme, WeeklyProgressSummary progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: theme.colorScheme.secondaryContainer, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(progress.performance['title'] as String? ?? 'أداء ممتاز',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(progress.performance['subtitle'] as String? ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(ThemeData theme, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoal(ThemeData theme, WeeklyProgressSummary progress) {
    final pct = (progress.goalProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: progress.goalProgress,
                trackColor: theme.colorScheme.outlineVariant,
                progressColor: theme.colorScheme.secondary,
                strokeWidth: 8,
              ),
              child: Center(
                child: Text('$pct%', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هدف الأسبوع', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${progress.sessionsCount} من ${progress.goalTarget} جلسات',
                  style: TextStyle(color: theme.colorScheme.outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme, WeeklyProgressSummary progress) {
    final arabicDayAbbr = {0: 'س', 1: 'ح', 2: 'خ', 3: 'ع', 4: 'ن', 5: 'ج', 6: 'س'};
    final stats = progress.dailyStats;

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final dayAbbr = arabicDayAbbr[i]!;
          final stat = stats.where((s) => s.dayAbbr == dayAbbr).firstOrNull;
              final height = (stat != null ? (stat.value * 80).clamp(4, 80) : 4.0).toDouble();
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6 + (height / 80) * 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Text(dayAbbr, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAchievementCard(ThemeData theme, AchievementModel achievement) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isCompleted
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            achievement.isCompleted ? Icons.emoji_events : Icons.lock_outline,
            color: achievement.isCompleted ? theme.colorScheme.primary : theme.colorScheme.outline,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (achievement.subtitle.isNotEmpty)
                  Text(achievement.subtitle,
                      style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('تعذر تحميل التقدم', style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
