import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/safe_json.dart';

final monthlyRevenueProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(analyticsRepositoryProvider).fetchRevenue();
});

final departmentDistributionProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(analyticsRepositoryProvider).fetchDepartmentDistribution();
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? _selectedAcademyId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canFilter = user?.role == 'super_admin';
    final academyIdFilter = canFilter ? _selectedAcademyId : user?.academy;

    final statsAsync = ref.watch(dashboardStatsProvider(academyIdFilter));
    final deptsAsync = ref.watch(departmentsProvider);

    final revenueAsync = ref.watch(monthlyRevenueProvider);
    final distributionAsync = ref.watch(departmentDistributionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية والنمو', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(dashboardStatsProvider(academyIdFilter));
          ref.refresh(monthlyRevenueProvider);
          ref.refresh(departmentDistributionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filters dropdown (super admin)
              if (canFilter) ...[
                deptsAsync.when(
                  data: (list) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkMuted : AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedAcademyId,
                          hint: const Text('فلترة حسب الأكاديمية (الكل)'),
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('جميع الأكاديميات')),
                            ...list.map((d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.nameAr))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedAcademyId = val;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
              ],

              // Revenue Overview Card
              statsAsync.when(
                data: (stats) {
                  return Column(
                    children: [
                      StatCard(
                        title: 'إجمالي الإيرادات المالية',
                        value: '${NumberFormatter.formatCurrency(stats.totalRevenue)} د.ل',
                        icon: Icons.account_balance_wallet,
                        iconColor: AppColors.secondary,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'نسبة تجديد الاشتراكات',
                              value: '%${stats.renewalRate.toString().toWesternDigits()}',
                              icon: Icons.sync,
                              iconColor: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'الاشتراكات النشطة',
                              value: stats.activeMemberships.toString().toWesternDigits(),
                              icon: Icons.check_circle,
                              iconColor: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, s) => Text('حدث خطأ أثناء تحميل الخلاصة: $e'),
              ),

              const SizedBox(height: 24),
              // Revenue Monthly Chart
              const Text(
                'منحنى نمو الإيرادات الشهرية',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              revenueAsync.when(
                data: (chartData) {
                  if (chartData.isEmpty) {
                    return const AppCard(child: Center(child: Text('لا توجد بيانات كافية لعرض المخطط البياني')));
                  }
                  return Container(
                    height: 240,
                    padding: const EdgeInsets.only(top: 24, bottom: 8, right: 16, left: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkMuted : AppColors.border.withOpacity(0.5)),
                    ),
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < chartData.length) {
                                  // Extract date representation e.g. "2026-06-01" to "06" month
                                  final monthStr = asString(chartData[idx]['month']) ?? '';
                                  if (monthStr.length >= 7) {
                                    return Text(monthStr.substring(5, 7).toWesternDigits(), style: const TextStyle(fontSize: 10));
                                  }
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        barGroups: chartData.map((item) {
                          final idx = chartData.indexOf(item);
                          final revenue = asDouble(item['revenue']) ?? 0.0;
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: revenue,
                                color: AppColors.primary,
                                width: 14,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (e, s) => Text('خطأ في تحميل المخطط: $e'),
              ),

              const SizedBox(height: 24),
              // Department distribution (Only if super_admin/reception)
              if (canFilter && _selectedAcademyId == null) ...[
                const Text(
                  'نسبة التوزيع الإجمالي للاعبين',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                distributionAsync.when(
                  data: (data) {
                    if (data.isEmpty) return const SizedBox.shrink();
                    return Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkMuted : AppColors.border.withOpacity(0.5)),
                      ),
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: data.map((item) {
                            final name = asString(item['department_name']) ?? 'بدون قسم';
                            final count = asInt(item['count']) ?? 0;
                            final idx = data.indexOf(item);
                            final colors = [
                              AppColors.primary,
                              AppColors.secondary,
                              AppColors.warning,
                              Colors.teal,
                              Colors.purple,
                            ];
                            return PieChartSectionData(
                              color: colors[idx % colors.length],
                              value: count.toDouble(),
                              title: '${count.toString().toWesternDigits()}',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              badgeWidget: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: colors[idx % colors.length]),
                                ),
                                child: Text(name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                              badgePositionPercentageOffset: 1.4,
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
