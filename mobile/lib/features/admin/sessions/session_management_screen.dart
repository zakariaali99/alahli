import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';

final _sessionsAdminProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getSessions();
});

class SessionManagementScreen extends ConsumerWidget {
  const SessionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(_sessionsAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الجلسات')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_sessionsAdminProvider.future),
        child: sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('لا توجد جلسات', style: theme.textTheme.bodyLarge),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (ctx, i) {
                final s = sessions[i];
                return _buildSessionCard(theme, s);
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
                Text('تعذر تحميل الجلسات', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => ref.invalidate(_sessionsAdminProvider), child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(ThemeData theme, Map<String, dynamic> s) {
    final name = s['name'] as String? ?? '';
    final category = s['category_display'] as String? ?? '';
    final date = s['date'] as String? ?? '';
    final time = s['time'] as String? ?? '';
    final location = s['location'] as String? ?? '';
    final trainerName = s['trainer_name'] as String? ?? '';
    final duration = s['duration_minutes'] as int? ?? 0;
    final isCompleted = s['is_completed'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: isCompleted ? Colors.green : theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(category, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(isCompleted ? 'مكتملة' : 'قادمة', style: TextStyle(color: isCompleted ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _infoChip(theme, Icons.calendar_today, '$date $time'),
              _infoChip(theme, Icons.timer_outlined, '$duration دقيقة'),
              _infoChip(theme, Icons.location_on_outlined, location),
              _infoChip(theme, Icons.person_outline, trainerName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
