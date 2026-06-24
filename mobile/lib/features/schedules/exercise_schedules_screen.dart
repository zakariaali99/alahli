import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/models/workout_session_model.dart';

class ExerciseSchedulesScreen extends ConsumerStatefulWidget {
  const ExerciseSchedulesScreen({super.key});

  @override
  ConsumerState<ExerciseSchedulesScreen> createState() => _ExerciseSchedulesScreenState();
}

class _ExerciseSchedulesScreenState extends ConsumerState<ExerciseSchedulesScreen> {
  int _selectedDay = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutsAsync = ref.watch(workoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جداول التمارين', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: workoutsAsync.when(
        data: (sessions) => _buildContent(theme, sessions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, List<WorkoutSessionModel> sessions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayChips(theme),
          const SizedBox(height: 20),
          ...sessions.map((s) => _buildSessionCard(theme, s)),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'لا توجد حصص متاحة لهذا اليوم',
                  style: TextStyle(color: theme.colorScheme.outline, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayChips(ThemeData theme) {
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final d = today.add(Duration(days: i - _selectedDay));
      final arabicDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return (arabicDays[d.weekday % 7], d.day.toString());
    });

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = index),
            child: Container(
              width: 64,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 0)
                    : Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index].$1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index].$2,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(ThemeData theme, WorkoutSessionModel session) {
    final accentColor = session.isCompleted
        ? theme.colorScheme.outline.withValues(alpha: 0.4)
        : theme.colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: session.isCompleted
                      ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
                      : const Color(0xFF2c694e).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  session.isCompleted ? 'مكتمل' : 'كثافة عالية',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: session.isCompleted ? theme.colorScheme.secondary : const Color(0xFF2c694e),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.fitness_center, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Text(session.location, style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
              const Spacer(),
              Icon(Icons.access_time, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Text('${session.time} | ${session.durationMinutes} دقيقة',
                  style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Text(session.trainerInitials,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.trainerName,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('مدرب معتمد',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 10)),
                ],
              ),
              const Spacer(),
              if (!session.isCompleted)
                ElevatedButton(
                  onPressed: () => context.push('/exercise-details?id=${session.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('حجز الآن', style: TextStyle(fontSize: 12)),
                ),
            ],
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
          Icon(Icons.wifi_off, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('تعذر تحميل جداول التمارين',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 16)),
        ],
      ),
    );
  }
}
