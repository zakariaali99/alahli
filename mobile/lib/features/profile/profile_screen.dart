import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final activeSubAsync = ref.watch(activeSubscriptionProvider);

    final user = authState.user;
    final bottomPad = MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'حسابي',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.settings, color: theme.colorScheme.outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Text(
                    (user?.fullNameAr.isNotEmpty == true ? user!.fullNameAr[0] : 'م'),
                    style: TextStyle(
                      fontSize: 38,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 2),
                    ),
                    child: Icon(Icons.edit, size: 14, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              user?.fullNameAr ?? 'مستخدم',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              activeSubAsync.valueOrNull != null
                  ? 'عضوية منذ ${_extractYear(activeSubAsync.valueOrNull!.startDate)}'
                  : 'عضوية',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),

            activeSubAsync.when(
              data: (sub) {
                if (sub == null) return const SizedBox.shrink();
                return _buildSubscriptionCard(theme, sub);
              },
              loading: () => _buildLoadingSkeleton(theme),
              error: (_, __) => _buildErrorState(theme),
            ),
            if (activeSubAsync.valueOrNull != null)
              const SizedBox(height: 28),

            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'المعلومات الشخصية',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            _buildFormField(
              theme,
              label: 'الاسم الكامل',
              value: user?.fullNameAr ?? '',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 4),
            _buildFormField(
              theme,
              label: 'رقم الهاتف',
              value: user?.phone ?? '',
              icon: Icons.phone,
              isLtr: true,
            ),
            const SizedBox(height: 4),
            _buildFormField(
              theme,
              label: 'القسم الرياضي',
              value: activeSubAsync.valueOrNull?.departmentName.isNotEmpty == true
                  ? activeSubAsync.valueOrNull!.departmentName
                  : '—',
              icon: Icons.fitness_center,
            ),
            const SizedBox(height: 4),
            _buildFormField(
              theme,
              label: 'تاريخ الميلاد',
              value: _birthDateFromUser(user),
              icon: Icons.cake,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
                  );
                },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('حفظ التغييرات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
            ),
            const SizedBox(height: 28),

            _SettingsItem(
              icon: Icons.card_membership_outlined,
              label: 'تفاصيل الاشتراك',
              onTap: () => context.push('/membership-details'),
            ),
            _SettingsItem(
              icon: Icons.qr_code,
              label: 'البطاقة الرقمية',
              onTap: () => context.go('/card'),
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              label: 'إعدادات التنبيهات',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.language,
              label: 'اللغة',
              trailing: Text('العربية', style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.info_outline,
              label: 'عن التطبيق',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(authStateProvider.notifier).logout();
                            context.go('/login');
                          },
                          child: const Text('تسجيل الخروج'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('تسجيل الخروج'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'مركز الأهلي الرياضي',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    bool isLtr = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              readOnly: true,
              textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.chevron_left, size: 18, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(ThemeData theme, dynamic sub) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(100, 100),
            painter: _DotPatternPainter(),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('نشط', style: TextStyle(color: theme.colorScheme.secondaryContainer, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                  Icon(Icons.workspace_premium, color: theme.colorScheme.secondaryContainer, size: 28),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sub.packageName ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'ينتهي: ${sub.endDate ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow;
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          'تعذر تحميل الاشتراك',
          style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
        ),
      ),
    );
  }
}

String _extractYear(String dateStr) {
  final dt = DateTime.tryParse(dateStr);
  if (dt != null) return '${dt.year}';
  return dateStr;
}

String _birthDateFromUser(dynamic user) {
  if (user == null) return '—';
  final detail = user.athleteDetail;
  if (detail == null) return '—';
  final birthDate = detail['birth_date'] as String?;
  if (birthDate == null || birthDate.isEmpty) return '—';
  final dt = DateTime.tryParse(birthDate);
  if (dt != null) {
    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
  return birthDate;
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const spacing = 15.0;
    const radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              trailing ??
                  Icon(Icons.chevron_left, size: 20, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
