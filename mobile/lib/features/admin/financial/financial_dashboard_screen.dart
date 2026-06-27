import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/widgets.dart';

class FinancialDashboardScreen extends ConsumerWidget {
  const FinancialDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final revenueAsync = ref.watch(revenueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير المالية')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(revenueProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إجمالي الإيرادات', style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('${stats.totalRevenue.toInt()} د.ل', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statInline(theme, 'معدل التجديد', '${stats.renewalRate}%'),
                              const SizedBox(width: 24),
                              _statInline(theme, 'اشتراكات نشطة', '${stats.activeMemberships}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _summaryCard(theme, Icons.people, 'إجمالي المشتركين', '${stats.totalAthletes}', Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _summaryCard(theme, Icons.repeat, 'عمليات التجديد', '${stats.renewalRate}%', Colors.green)),
                      ],
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Text('الإيرادات الشهرية', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              revenueAsync.when(
                data: (revenues) => Column(
                  children: revenues.map((r) => _revenueRow(theme, r.month, r.revenue)).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text('تعذر التحميل', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statInline(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _summaryCard(ThemeData theme, IconData icon, String title, String value, Color color) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _revenueRow(ThemeData theme, String month, double amount) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(month.length >= 7 ? month.substring(0, 7) : month, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text('${amount.toInt()} د.ل', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
