import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/dashboard_stats.dart';
import '../../../core/widgets/widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, color: theme.colorScheme.onPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: statsAsync.when(
            data: (stats) => _buildDashboardContent(context, theme, stats),
            loading: () => _buildLoadingSkeleton(theme),
            error: (e, _) => _buildErrorState(context, theme, e, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, ThemeData theme, DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 20),
        _buildKPIRow1(theme, stats),
        const SizedBox(height: 12),
        _buildKPIRow2(theme, stats),
        const SizedBox(height: 24),
        _buildQuickActions(context, theme),
        const SizedBox(height: 24),
        _buildRecentActivity(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نظرة عامة على أداء المركز',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Text(
          'مؤشرات الأداء الرئيسية',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildKPIRow1(ThemeData theme, DashboardStats stats) {
    return Row(
      children: [
        Expanded(child: _buildKPICard(theme, icon: Icons.people, label: 'المشتركين النشطين', value: '${stats.activeMemberships}', color: theme.colorScheme.secondary, trend: '+5%', trendUp: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildKPICard(theme, icon: Icons.attach_money, label: 'إجمالي الإيرادات', value: _formatCurrency(stats.totalRevenue), color: theme.colorScheme.primary, trend: '+12%', trendUp: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildKPICard(theme, icon: Icons.fitness_center, label: 'إجمالي المشتركين', value: '${stats.totalAthletes}', color: theme.colorScheme.tertiary, trend: '+8%', trendUp: true)),
      ],
    );
  }

  Widget _buildKPIRow2(ThemeData theme, DashboardStats stats) {
    return Row(
      children: [
        Expanded(child: _buildKPICard(theme, icon: Icons.new_releases, label: 'جدد هذا الشهر', value: '+${stats.newThisMonth}', color: Colors.green, trend: '+15%', trendUp: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildKPICard(theme, icon: Icons.warning_amber, label: 'منتهي الصلاحية', value: '${stats.expiredMemberships}', color: Colors.red, trend: '-3%', trendUp: false)),
        const SizedBox(width: 12),
        Expanded(child: _buildKPICard(theme, icon: Icons.replay, label: 'معدل التجديد', value: '${stats.renewalRate}%', color: Colors.blue, trend: '+2%', trendUp: true)),
      ],
    );
  }

  Widget _buildKPICard(ThemeData theme, {required IconData icon, required String label, required String value, required Color color, String? trend, bool trendUp = true}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (trendUp ? Colors.green : Colors.red).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendUp ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: trendUp ? Colors.green : Colors.red),
                      const SizedBox(width: 2),
                      Text(trend, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: trendUp ? Colors.green : Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    final actions = [
      _QuickAction(icon: Icons.person_add, label: 'إضافة مشترك', route: '/admin/subscribers', color: theme.colorScheme.primary),
      _QuickAction(icon: Icons.fact_check, label: 'الموافقات والطلبات', route: '/admin/approvals', color: Colors.blue),
      _QuickAction(icon: Icons.notification_add, label: 'إرسال تنبيه', route: '/admin/notifications', color: Colors.orange),
      _QuickAction(icon: Icons.card_giftcard, label: 'الباقات', route: '/admin/packages', color: Colors.purple),
      _QuickAction(icon: Icons.event, label: 'الجلسات', route: '/admin/sessions', color: Colors.teal),
      _QuickAction(icon: Icons.trending_up, label: 'التقارير المالية', route: '/admin/financial', color: Colors.green),
      _QuickAction(icon: Icons.fitness_center, label: 'التمارين', route: '/admin/exercises', color: Colors.deepOrange),
      _QuickAction(icon: Icons.groups, label: 'المجموعات', route: '/admin/groups', color: Colors.indigo),
      _QuickAction(icon: Icons.people_alt, label: 'الموظفين', route: '/admin/staff', color: Colors.red),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 360 ? 3 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الإجراءات السريعة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: actions.length,
          itemBuilder: (ctx, i) => _buildQuickActionCard(context, theme, actions[i]),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(BuildContext context, ThemeData theme, _QuickAction action) {
    return AppCard(
      onTap: () => context.push(action.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: action.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(action.icon, color: action.color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme) {
    final activities = [
      _Activity(icon: Icons.person_add, title: 'مشترك جديد', subtitle: 'أحمد محمد - باقة 3 أشهر', time: 'منذ ساعتان', color: Colors.green),
      _Activity(icon: Icons.payment, title: 'دفعة مستلمة', subtitle: 'سارة أحمد - 1500 د.ل', time: 'منذ 4 ساعات', color: Colors.blue),
      _Activity(icon: Icons.warning_amber, title: 'اشتراك منتهي', subtitle: 'محمد علي - باقة 6 أشهر', time: 'منذ 6 ساعات', color: Colors.orange),
      _Activity(icon: Icons.replay, title: 'تم التجديد', subtitle: 'فاطمة حسن - باقة سنوية', time: 'أمس', color: Colors.purple),
      _Activity(icon: Icons.fitness_center, title: 'جلسة مكتملة', subtitle: 'مجموعة الكبار - تمارين الكارديو', time: 'أمس', color: Colors.teal),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('آخر النشاطات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text('عرض الكل')),
          ],
        ),
        const SizedBox(height: 8),
        ...activities.map((a) => _buildActivityItem(theme, a)),
      ],
    );
  }

  Widget _buildActivityItem(ThemeData theme, _Activity a) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: a.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(a.icon, color: a.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(a.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(a.time, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Column(
      children: [
        _buildHeader(theme),
        const SizedBox(height: 20),
        _buildKPIRow1Skeleton(theme),
        const SizedBox(height: 12),
        _buildKPIRow2Skeleton(theme),
        const SizedBox(height: 240),
      ],
    );
  }

  Widget _buildKPIRow1Skeleton(ThemeData theme) => Row(
    children: [
      Expanded(child: _skeletonCard(theme)),
      const SizedBox(width: 12),
      Expanded(child: _skeletonCard(theme)),
      const SizedBox(width: 12),
      Expanded(child: _skeletonCard(theme)),
    ],
  );

  Widget _buildKPIRow2Skeleton(ThemeData theme) => Row(
    children: [
      Expanded(child: _skeletonCard(theme)),
      const SizedBox(width: 12),
      Expanded(child: _skeletonCard(theme)),
      const SizedBox(width: 12),
      Expanded(child: _skeletonCard(theme)),
    ],
  );

  Widget _skeletonCard(ThemeData theme) => ShimmerLoading(
    height: 120,
    borderRadius: 16,
  );

  Widget _buildErrorState(BuildContext context, ThemeData theme, Object e, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text('تعذر تحميل البيانات', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => ref.invalidate(dashboardStatsProvider), child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }

  String _formatCurrency(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}م';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}ك';
    return value.toStringAsFixed(0);
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  _QuickAction({required this.icon, required this.label, required this.route, required this.color});
}

class _Activity {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  _Activity({required this.icon, required this.title, required this.subtitle, required this.time, required this.color});
}