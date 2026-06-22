import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeBrand = ref.watch(brandProvider);
    final authState = ref.watch(authStateProvider);
    final activeSubAsync = ref.watch(activeSubscriptionProvider);

    final user = authState.user;

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    child: Text(
                      (user?.fullNameAr.isNotEmpty == true ? user!.fullNameAr[0] : 'م'),
                      style: TextStyle(
                        fontSize: 32,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullNameAr ?? 'مستخدم',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _roleLabel(user?.role ?? ''),
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Membership summary
            activeSubAsync.when(
              data: (sub) {
                if (sub == null) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الاشتراك الحالي',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2c694e),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 12, color: const Color(0xFF95d4b3)),
                                const SizedBox(width: 4),
                                const Text(
                                  'نشط',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoCol('الباقة', sub.packageName),
                          _infoCol('رقم العضوية', sub.membershipNumber),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (activeSubAsync.valueOrNull != null)
              const SizedBox(height: 28),

            // Settings items
            _SettingsItem(
              icon: Icons.person_outline,
              label: 'تعديل الملف الشخصي',
              onTap: () {},
            ),
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
            const SizedBox(height: 24),

            // Academy toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_horiz, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'تبديل الأكاديمية',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Switch(
                    value: activeBrand == SportsBrand.awsAcademy,
                    onChanged: (val) {
                      ref.read(brandProvider.notifier).state =
                          val ? SportsBrand.awsAcademy : SportsBrand.alAhly;
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout
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
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
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
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'مدير النظام';
      case 'reception':
        return 'موظف استقبال';
      case 'viewer':
        return 'مشاهد';
      default:
        return 'مستخدم';
    }
  }

  Widget _infoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
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
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_left, size: 20, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
