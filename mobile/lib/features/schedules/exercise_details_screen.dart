import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/models/exercise_model.dart';

class ExerciseDetailsScreen extends ConsumerWidget {
  final int? exerciseId;

  const ExerciseDetailsScreen({super.key, this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (exerciseId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل التمرين'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        body: Center(
          child: Text('لم يتم تحديد التمرين', style: TextStyle(color: theme.colorScheme.error)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل التمرين'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: FutureBuilder<ExerciseModel>(
        future: ref.read(workoutRepositoryProvider).getExercise(exerciseId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('تعذر تحميل التمرين',
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
              ),
            );
          }
          return _buildContent(context, theme, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, ThemeData theme, ExerciseModel exercise) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.imageUrl.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(exercise.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(exercise.description,
                    style: TextStyle(color: theme.colorScheme.outline, height: 1.6)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTag(theme, Icons.fitness_center, 'قوة'),
                    if (exercise.calories > 0)
                      _buildTag(theme, Icons.local_fire_department, '${exercise.calories} سعرة'),
                  ],
                ),
                const SizedBox(height: 24),
                if (exercise.movements.isNotEmpty) ...[
                  Text('التمارين', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...exercise.movements.map((m) => _buildMovementCard(theme, m)),
                ],
                if (exercise.equipment.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('الأجهزة والمعدات',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...exercise.equipment.map((e) => _buildEquipmentItem(theme, e)),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('تم بدء التمرين بنجاح')),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('بدء التمرين'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildMovementCard(ThemeData theme, ExerciseMovementModel movement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (movement.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(movement.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
            ),
          if (movement.imageUrl.isNotEmpty) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${movement.sets} مجموعات × ${movement.reps} تكرارات',
                    style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentItem(ThemeData theme, ExerciseEquipmentModel equipment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.fitness_center, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(equipment.name, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
