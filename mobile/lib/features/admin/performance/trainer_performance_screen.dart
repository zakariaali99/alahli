import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';

final _trainerPerfListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getTrainers();
});

class TrainerPerformanceScreen extends ConsumerWidget {
  const TrainerPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trainersAsync = ref.watch(_trainerPerfListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('أداء المدربين')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_trainerPerfListProvider.future),
        child: trainersAsync.when(
          data: (trainers) {
            if (trainers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('لا يوجد مدربين', style: theme.textTheme.bodyLarge),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trainers.length,
              itemBuilder: (ctx, i) {
                final t = trainers[i];
                return _buildPerformanceCard(theme, t);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text('تعذر تحميل أداء المدربين', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => ref.invalidate(_trainerPerfListProvider), child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(ThemeData theme, Map<String, dynamic> t) {
    final name = t['full_name_ar'] as String? ?? '';
    final role = t['role'] as String? ?? '';
    final rating = double.tryParse(t['rating']?.toString() ?? '') ?? 0.0;
    final experience = t['experience_years'] as int? ?? 0;
    final classes = t['classes'] as List? ?? [];
    final image = t['profile_image'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: image.isEmpty
                    ? Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    Text(role, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(i < rating.round() ? Icons.star : Icons.star_border, color: Colors.amber, size: 16)),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$experience+ سنة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat(theme, 'الجلسات', classes.length.toString(), Icons.fitness_center),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(ThemeData theme, String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
