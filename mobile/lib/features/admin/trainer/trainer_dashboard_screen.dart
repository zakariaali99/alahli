import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/widgets.dart';

final _trainersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getTrainers();
});

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trainersAsync = ref.watch(_trainersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المدربين')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_trainersListProvider.future),
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
                return _buildTrainerCard(theme, t);
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
                Text('تعذر تحميل المدربين'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => ref.invalidate(_trainersListProvider), child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainerCard(ThemeData theme, Map<String, dynamic> t) {
    final name = t['full_name_ar'] as String? ?? '';
    final role = t['role'] as String? ?? '';
    final rating = t['rating'] as String? ?? '0';
    final experience = t['experience_years'] as int? ?? 0;
    final bio = t['bio'] as String? ?? '';
    final image = t['profile_image'] as String? ?? '';
    final classes = t['classes'] as List? ?? [];

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: image.isEmpty ? Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(role, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(rating, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Icon(Icons.work_history, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text('$experience سنوات', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(bio, style: theme.textTheme.bodySmall),
          ],
          if (classes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text('الجلسات:', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            ...classes.map((c) {
              final m = c as Map<String, dynamic>;
              final title = m['title'] as String? ?? '';
              final intensity = m['intensity'] as String? ?? '';
              final price = m['price_display'] as String? ?? '';
              final duration = m['duration_minutes'] as int? ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text('$intensity • $duration دقيقة', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Text(price, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
