import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/ui_helpers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التنبيهات والطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(notificationsProvider),
        child: notificationsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(message: 'لا توجد تنبيهات مسجلة حالياً');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final notify = list[index];

                return AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notify.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notify.body,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              safeDateTimeParse(notify.createdAt) != null
                                  ? NumberFormatter.formatDateTime(safeDateTimeParse(notify.createdAt)!)
                                  : '',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const ShimmerList(),
          error: (err, stack) => AppErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.refresh(notificationsProvider),
          ),
        ),
      ),
    );
  }
}
