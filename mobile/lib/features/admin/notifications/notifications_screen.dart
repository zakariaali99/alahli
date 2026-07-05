import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/paginated_providers.dart';
import '../../../core/providers/paginated_list_notifier.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/staggered_list_item.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/ui_helpers.dart';
import '../../../core/models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsPaginatedProvider(NotificationFilter.defaultFilter).notifier).loadMore();
    }
  }

  Future<void> _markAsRead(NotificationModel notify) async {
    if (notify.isRead) return;
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(notify.id);
      ref.read(notificationsPaginatedProvider(NotificationFilter.defaultFilter).notifier).refresh();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      ref.read(notificationsPaginatedProvider(NotificationFilter.defaultFilter).notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديد جميع التنبيهات كمقروءة')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifState = ref.watch(notificationsPaginatedProvider(NotificationFilter.defaultFilter));

    final unreadCount = notifState.items.where((n) => !n.isRead).length;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'سجل التنبيهات والطلبات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('تحديد الكل كمقروء', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(notificationsPaginatedProvider(NotificationFilter.defaultFilter).notifier).refresh(),
              child: _buildBody(notifState, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PaginatedListState<NotificationModel> state, bool isDark) {
    if (state.state == PaginatedState.loading) {
      return const ShimmerList();
    }

    if (state.state == PaginatedState.error) {
      return AppErrorWidget(
        errorMessage: state.error ?? 'خطأ غير معروف',
        onRetry: () => ref.read(notificationsPaginatedProvider(NotificationFilter.defaultFilter).notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          EmptyState(message: 'لا توجد تنبيهات مسجلة حالياً'),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + (state.hasNext ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (index == state.items.length + (state.hasNext ? 1 : 0)) {
          return const SizedBox(height: 100);
        }
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final notify = state.items[index];

        return StaggeredListItem(
          index: index,
          child: GestureDetector(
            onTap: () => _markAsRead(notify),
            child: AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: notify.isRead
                          ? Colors.grey.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      notify.isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: notify.isRead ? Colors.grey : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notify.title,
                                style: TextStyle(
                                  fontWeight: notify.isRead ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (!notify.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notify.body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: notify.isRead ? Colors.grey : null,
                          ),
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
            ),
          ),
        );
      },
    );
  }
}
