import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/announcement_model.dart';
import '../../core/models/notification_model.dart';
import '../../core/widgets/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

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
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          final announcements = announcementsAsync.asData?.value ?? [];
          final allItems = [...announcements, ...notifications];
          if (allItems.isEmpty) {
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
            final unreadCount = allItems.whereType<NotificationModel>().where((n) => !n.isRead).length;
            final bottomPad = MediaQuery.of(context).padding.bottom + 100;
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
              itemCount: allItems.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader(theme, ref, unreadCount);
                }
                final item = allItems[index - 1];
                if (item is AnnouncementModel) {
                  return _NotificationCard(
                    title: item.title,
                    body: item.body,
                    time: _formatTime(item.createdAt),
                    isRead: true,
                    type: NotificationType.management,
                    onTap: () {},
                  );
                }
                final notif = item as NotificationModel;
                final type = _classifyNotification(notif.title, notif.body);
                return _NotificationCard(
                  title: notif.title,
                  body: notif.body,
                  time: _formatTime(notif.createdAt),
                  isRead: notif.isRead,
                  type: type,
                  onTap: () async {
                    if (!notif.isRead) {
                      await ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                      ref.invalidate(notificationsProvider);
                    }
                  },
                );
              },
            );
        },
        loading: () => const ShimmerList(),
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

  Widget _buildHeader(ThemeData theme, WidgetRef ref, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              unreadCount > 0 ? 'لديك $unreadCount رسائل غير مقروءة' : 'جميع الرسائل مقروءة',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () async {
                await ref.read(notificationRepositoryProvider).markAllAsRead();
                ref.invalidate(notificationsProvider);
              },
              child: const Text('تحديد الكل كمقروء', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  NotificationType _classifyNotification(String title, String body) {
    if (title.contains('انتهاء') || title.contains('منتهي') || title.contains('تجديد')) {
      return NotificationType.alert;
    }
    if (title.contains('إدارة') || title.contains('إعلان') || title.contains('إشعار')) {
      return NotificationType.management;
    }
    if (title.contains('أخبار') || title.contains('جديد')) {
      return NotificationType.news;
    }
    return NotificationType.general;
  }

  String _formatTime(String createdAt) {
    if (createdAt.isEmpty) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return createdAt;
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative) return 'الآن';
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) {
      final m = diff.inMinutes;
      if (m == 1) return 'منذ دقيقة واحدة';
      if (m == 2) return 'منذ دقيقتين';
      return 'منذ $m دقيقة';
    }
    if (diff.inDays < 1) {
      final h = diff.inHours;
      if (h == 1) return 'منذ ساعة واحدة';
      if (h == 2) return 'منذ ساعتين';
      return 'منذ $h ساعة';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

enum NotificationType { alert, management, news, general, subscription }

class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final NotificationType type;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color iconBgColor;
    Color iconColor;
    IconData icon;
    Color? cardBg;
    Color? cardBorder;
    bool showCta = false;
    bool showImage = false;

    switch (type) {
      case NotificationType.alert:
        icon = Icons.error_outline;
        iconBgColor = theme.colorScheme.error.withValues(alpha: 0.15);
        iconColor = theme.colorScheme.error;
        cardBg = theme.colorScheme.error.withValues(alpha: 0.04);
        cardBorder = theme.colorScheme.error.withValues(alpha: 0.12);
        showCta = true;
      case NotificationType.management:
        icon = Icons.manage_accounts;
        iconBgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
        iconColor = theme.colorScheme.primary;
        cardBg = isRead ? null : theme.colorScheme.primary.withValues(alpha: 0.03);
        cardBorder = isRead ? null : theme.colorScheme.primary.withValues(alpha: 0.15);
      case NotificationType.news:
        icon = Icons.newspaper;
        iconBgColor = Colors.amber.withValues(alpha: 0.15);
        iconColor = Colors.amber[700]!;
        showImage = true;
      case NotificationType.general:
        icon = Icons.campaign;
        iconBgColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
        iconColor = theme.colorScheme.outline;
      default:
        icon = Icons.notifications;
        iconBgColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.2);
        iconColor = theme.colorScheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isRead ? 0.7 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg ?? (isRead
                  ? theme.colorScheme.surfaceContainerLow
                  : theme.colorScheme.surfaceContainerLow),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cardBorder ?? (isRead
                    ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                width: isRead ? 0.5 : 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showImage)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.newspaper, color: Colors.white, size: 24),
                    ),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          if (!isRead)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          if (showCta)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'تجديد',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_back, size: 12, color: theme.colorScheme.error),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
