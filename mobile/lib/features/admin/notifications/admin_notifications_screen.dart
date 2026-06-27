import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';

final _notificationsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getNotifications();
});

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifsAsync = ref.watch(_notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          TextButton.icon(
            onPressed: () => _showSendDialog(context, ref),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('إرسال'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_notificationsListProvider.future),
        child: notifsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('لا توجد إشعارات', style: theme.textTheme.bodyLarge),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (ctx, i) {
                final n = notifications[i];
                return _buildNotificationCard(theme, n);
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
                const Text('تعذر تحميل الإشعارات'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => ref.invalidate(_notificationsListProvider), child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme, Map<String, dynamic> n) {
    final title = n['title'] as String? ?? '';
    final body = n['body'] as String? ?? '';
    final isRead = n['is_read'] as bool? ?? true;
    final createdAt = n['created_at'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead ? theme.colorScheme.surface : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.notifications, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(createdAt, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
          ],
        ),
        trailing: isRead
            ? null
            : Container(width: 8, height: 8,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              ),
      ),
    );
  }

  void _showSendDialog(BuildContext context, WidgetRef ref) {
    final titleCtl = TextEditingController();
    final bodyCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إرسال إشعار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'العنوان')),
            const SizedBox(height: 12),
            TextField(controller: bodyCtl, decoration: const InputDecoration(labelText: 'النص'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtl.text.isEmpty || bodyCtl.text.isEmpty) return;
              try {
                await ref.read(adminRepositoryProvider).sendNotification({
                  'title': titleCtl.text,
                  'body': bodyCtl.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(_notificationsListProvider);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}
