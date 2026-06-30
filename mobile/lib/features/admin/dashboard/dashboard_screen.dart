import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/safe_json.dart';
import '../../../core/helpers/responsive_helper.dart';

final dashboardDistributionProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(analyticsRepositoryProvider).fetchDepartmentDistribution();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedAcademyId;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final canFilter = user?.role == 'super_admin';
    final academyIdFilter = canFilter ? _selectedAcademyId : user?.academy;

    final statsAsync = ref.watch(dashboardStatsProvider(academyIdFilter));
    final departmentsAsync = ref.watch(departmentsProvider);
    final distributionAsync = ref.watch(dashboardDistributionProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider(academyIdFilter));
        ref.invalidate(departmentsProvider);
        ref.invalidate(dashboardDistributionProvider);
        _animController.reset();
        _animController.forward();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkPrimaryGradientStart, AppColors.darkPrimaryGradientEnd]
                        : [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، ${user?.firstNameAr ?? ''} 👋',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إليك نظرة عامة على الأداء اليوم في مركز الأهلي',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions Panel (Material 3 style)
            const Text(
              'إجراءات سريعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              color: isDark ? AppColors.darkCard : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickActionItem(
                      context: context,
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'إضافة لاعب',
                      onTap: () => context.push('/dashboard/athletes/add'),
                      isDark: isDark,
                    ),
                    _buildQuickActionItem(
                      context: context,
                      icon: Icons.credit_card_outlined,
                      label: 'إضافة اشتراك',
                      onTap: () => context.push('/dashboard/subscriptions/add'),
                      isDark: isDark,
                    ),
                    _buildQuickActionItem(
                      context: context,
                      icon: Icons.qr_code_scanner_outlined,
                      label: 'فحص QR',
                      onTap: () => context.push('/dashboard/verify'),
                      isDark: isDark,
                    ),
                    _buildQuickActionItem(
                      context: context,
                      icon: Icons.notifications_none_outlined,
                      label: 'التنبيهات',
                      onTap: () => context.push('/dashboard/notifications'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Academy Filter Dropdown (Super Admin only)
            if (canFilter) ...[
              departmentsAsync.when(
                data: (list) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedAcademyId,
                        hint: const Text('كل الأكاديميات'),
                        isExpanded: true,
                        dropdownColor: colorScheme.surface,
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
              const SizedBox(height: 20),
            ],

            // Statistics Header
            const Text(
              'الاحصائيات والنشاط',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            statsAsync.when(
              data: (stats) {
                if (!_animController.isCompleted && !_animController.isAnimating) {
                  _animController.forward();
                }

                final statCards = [
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
                ];

                return Column(
                  children: [
                    GridView.count(
                      crossAxisCount: ResponsiveHelper.isSmallPhone(context) ? 1 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: ResponsiveHelper.isSmallPhone(context) ? 3.0 : 1.45,
                      children: List.generate(statCards.length, (index) {
                        final animation = CurvedAnimation(
                          parent: _animController,
                          curve: Interval(
                            (index / statCards.length) * 0.5,
                            ((index + 1) / statCards.length) * 0.5 + 0.5,
                            curve: Curves.easeOut,
                          ),
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: statCards[index],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animController,
                        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                      ),
                      child: StatCard(
                        title: AppStrings.totalRevenue,
                        value: '${NumberFormatter.formatCurrency(stats.totalRevenue)} د.ل',
                        icon: Icons.monetization_on,
                        iconColor: AppColors.gold,
                      ),
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

            const SizedBox(height: 28),
            // Department distribution section (Super Admin only)
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
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: data.map((item) {
                          final name = asString(item['department_name']) ?? 'بدون قسم';
                          final count = asInt(item['count']) ?? 0;
                          final index = data.indexOf(item);
                          final colors = [
                            AppColors.primary,
                            AppColors.secondary,
                            AppColors.warning,
                            Colors.teal,
                            Colors.pink,
                            Colors.amber,
                          ];
                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: count.toDouble(),
                            title: count.toString().toWesternDigits(),
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
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
