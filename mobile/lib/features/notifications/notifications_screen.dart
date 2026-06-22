import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التنبيهات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text(
              'تحديد الكل كمقروء',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد تنبيهات',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _NotificationCard(
                title: item.title,
                body: item.body,
                time: _formatTime(item.createdAt),
                isRead: item.isRead,
                icon: item.title.contains('انتهاء') || item.title.contains('منتهي')
                    ? Icons.schedule
                    : Icons.notifications,
                onTap: () {
                  if (!item.isRead) {
                    ref.read(notificationRepositoryProvider).markAsRead(item.id);
                    ref.invalidate(notificationsProvider);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('حدث خطأ في تحميل التنبيهات'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String createdAt) {
    if (createdAt.isEmpty) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return createdAt;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final IconData icon;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? theme.cardTheme.color
                : theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
              width: isRead ? 0.5 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isRead
                      ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isRead
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isRead) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'جديد',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
