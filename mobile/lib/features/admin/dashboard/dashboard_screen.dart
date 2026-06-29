import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/safe_json.dart';
import '../../../core/models/user_model.dart';
import '../../../core/helpers/ui_helpers.dart';
import 'package:go_router/go_router.dart';

final dashboardDistributionProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(analyticsRepositoryProvider).fetchDepartmentDistribution();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int? _selectedAcademyId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine if user can filter by academy (super_admin)
    final canFilter = user?.role == 'super_admin';

    // If manager, auto-set their assigned academy
    final academyIdFilter = canFilter ? _selectedAcademyId : user?.academy;

    final statsAsync = ref.watch(dashboardStatsProvider(academyIdFilter));
    final departmentsAsync = ref.watch(departmentsProvider);
    final distributionAsync = ref.watch(dashboardDistributionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle, style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: user?.photo != null ? NetworkImage(user!.photo!) : null,
              child: user?.photo == null
                  ? Text(safeInitials(user?.firstNameAr), style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context, user),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider(academyIdFilter));
          ref.invalidate(departmentsProvider);
          ref.invalidate(dashboardDistributionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Text(
                'مرحباً، ${user?.fullNameAr ?? ''}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'إليك نظرة عامة على الأداء اليوم',
                style: TextStyle(
                  color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Academy selection dropdown (only if super_admin)
              if (canFilter) ...[
                departmentsAsync.when(
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
                          hint: const Text('كل الأكاديميات'),
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('كل الأكاديميات'),
                            ),
                            ...list.map((dept) => DropdownMenuItem<int?>(
                                  value: dept.id,
                                  child: Text(dept.nameAr),
                                )),
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

              // Metrics Grid
              statsAsync.when(
                data: (stats) {
                  return Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 2,
                        childAspectRatio: 1.75,
                        children: [
                          StatCard(
                            title: AppStrings.totalAthletes,
                            value: NumberFormatter.formatNumber(stats.totalAthletes),
                            icon: Icons.people,
                            iconColor: AppColors.primary,
                          ),
                          StatCard(
                            title: AppStrings.activeSubscriptions,
                            value: NumberFormatter.formatNumber(stats.activeMemberships),
                            icon: Icons.check_circle,
                            iconColor: AppColors.secondary,
                          ),
                          StatCard(
                            title: AppStrings.expiredSubscriptions,
                            value: NumberFormatter.formatNumber(stats.expiredMemberships),
                            icon: Icons.dangerous,
                            iconColor: AppColors.destructive,
                          ),
                          StatCard(
                            title: AppStrings.expiringSoon,
                            value: NumberFormatter.formatNumber(stats.expiringSoon),
                            icon: Icons.warning,
                            iconColor: AppColors.warning,
                          ),
                          StatCard(
                            title: AppStrings.newAthletesThisMonth,
                            value: NumberFormatter.formatNumber(stats.newThisMonth),
                            icon: Icons.person_add,
                            iconColor: Colors.teal,
                          ),
                          StatCard(
                            title: AppStrings.renewalRate,
                            value: '%${stats.renewalRate}',
                            icon: Icons.autorenew,
                            iconColor: Colors.deepPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Revenue Card
                      StatCard(
                        title: AppStrings.totalRevenue,
                        value: '${NumberFormatter.formatCurrency(stats.totalRevenue)} د.ل',
                        icon: Icons.monetization_on,
                        iconColor: AppColors.gold,
                      ),
                    ],
                  );
                },
                loading: () => ShimmerGrid(itemCount: 6),
                error: (err, stack) => AppErrorWidget(
                  errorMessage: err.toString(),
                  onRetry: () => ref.refresh(dashboardStatsProvider(academyIdFilter)),
                ),
              ),

              const SizedBox(height: 24),
              // Pie Chart: distribution of athletes by academy (Only show if multiple exist)
              if (canFilter && _selectedAcademyId == null) ...[
                const Text(
                  'توزيع اللاعبين حسب الأكاديمية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            // Generate unique index/color helper
                            final index = data.indexOf(item);
                            final colors = [
                              AppColors.primary,
                              AppColors.secondary,
                              AppColors.warning,
                              Colors.teal,
                              Colors.pink,
                              Colors.amber
                            ];
                            return PieChartSectionData(
                              color: colors[index % colors.length],
                              value: count.toDouble(),
                              title: '${count.toString().toWesternDigits()}',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              badgeWidget: _Badge(
                                name,
                                size: 16,
                                borderColor: colors[index % colors.length],
                              ),
                              badgePositionPercentageOffset: 1.3,
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

  Widget _buildDrawer(BuildContext context, UserModel? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(user?.fullNameAr ?? ''),
            accountEmail: Text(user?.phone ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white24,
              backgroundImage: user?.photo != null ? NetworkImage(user!.photo!) : null,
              child: user?.photo == null
                  ? Text(
                      safeInitials(user?.firstNameAr),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('الاشتراكات'),
            onTap: () {
              Navigator.pop(context);
              context.go('/subscriptions');
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('الفحص السريع (QR)'),
            onTap: () {
              Navigator.pop(context);
              context.go('/verify');
            },
          ),
          if (user?.role == 'super_admin') ...[
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('الأكاديميات'),
              onTap: () {
                Navigator.pop(context);
                context.go('/academies');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('المدربين'),
              onTap: () {
                Navigator.pop(context);
                context.go('/coaches');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('الموظفين (Staff)'),
              onTap: () {
                Navigator.pop(context);
                context.go('/staff');
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('التقارير المالية والنمو'),
            onTap: () {
              Navigator.pop(context);
              context.go('/reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('سجل التنبيهات'),
            onTap: () {
              Navigator.pop(context);
              context.go('/notifications');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.destructive),
            title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.destructive)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.foreground,
        ),
      ),
    );
  }
}
