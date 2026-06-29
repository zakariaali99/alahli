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

    final canFilter = user?.role == 'super_admin';
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
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: user?.photo != null ? NetworkImage(user!.photo!) : null,
              child: user?.photo == null
                  ? Text(safeInitials(user?.firstNameAr), style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context, user, colorScheme),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider(academyIdFilter));
          ref.invalidate(departmentsProvider);
          ref.invalidate(dashboardDistributionProvider);
          _animController.reset();
          _animController.forward();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      colors: theme.brightness == Brightness.dark
                          ? [AppColors.darkPrimaryGradientStart, AppColors.darkPrimaryGradientEnd]
                          : [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (theme.brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3),
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
                        'إليك نظرة عامة على الأداء اليوم',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                const SizedBox(height: 16),
              ],

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
                        mainAxisSpacing: 12, // increased from 2 to 12
                        childAspectRatio: ResponsiveHelper.isSmallPhone(context) ? 3.0 : ResponsiveHelper.getGridAspectRatio(context, itemHeight: 90),
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

              const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserModel? user, ColorScheme colorScheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: user?.photo != null ? NetworkImage(user!.photo!) : null,
                  child: user?.photo == null
                      ? Text(
                          safeInitials(user?.firstNameAr),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullNameAr ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone.toWesternDigits() ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _DrawerTile(
            icon: Icons.credit_card,
            label: 'الاشتراكات',
            onTap: () { Navigator.pop(context); context.go('/subscriptions'); },
          ),
          _DrawerTile(
            icon: Icons.qr_code_scanner,
            label: 'الفحص السريع (QR)',
            onTap: () { Navigator.pop(context); context.go('/verify'); },
          ),
          if (user?.role == 'super_admin') ...[
            _DrawerTile(
              icon: Icons.business,
              label: 'الأكاديميات',
              onTap: () { Navigator.pop(context); context.go('/academies'); },
            ),
            _DrawerTile(
              icon: Icons.sports,
              label: 'المدربون',
              onTap: () { Navigator.pop(context); context.go('/coaches'); },
            ),
            _DrawerTile(
              icon: Icons.card_membership,
              label: 'الباقات',
              onTap: () { Navigator.pop(context); context.go('/packages'); },
            ),
            _DrawerTile(
              icon: Icons.admin_panel_settings,
              label: 'الموظفون',
              onTap: () { Navigator.pop(context); context.go('/staff'); },
            ),
          ],
          _DrawerTile(
            icon: Icons.bar_chart,
            label: 'التقارير المالية والنمو',
            onTap: () { Navigator.pop(context); context.go('/reports'); },
          ),
          _DrawerTile(
            icon: Icons.notifications_outlined,
            label: 'سجل التنبيهات',
            onTap: () { Navigator.pop(context); context.go('/notifications'); },
          ),
          _DrawerTile(
            icon: Icons.settings,
            label: 'الإعدادات',
            onTap: () { Navigator.pop(context); context.go('/settings'); },
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.logout,
            label: 'تسجيل الخروج',
            iconColor: colorScheme.error,
            textColor: colorScheme.error,
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(
        label,
        style: TextStyle(color: textColor ?? theme.colorScheme.onSurface),
      ),
      onTap: onTap,
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
