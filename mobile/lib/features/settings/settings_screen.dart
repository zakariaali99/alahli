import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التفضيلات',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.outline,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _settingsGroup(
              theme,
              children: [
                _settingsRow(
                  theme, Icons.language, 'اللغة',
                  onTap: () => _showSnack(context, 'سيتم إضافة خيار تغيير اللغة قريباً'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('العربية', style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_left, size: 18, color: theme.colorScheme.outline),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  theme, Icons.dark_mode, 'الوضع الليلي',
                  trailing: Switch(
                    value: ref.watch(themeModeProvider) == ThemeMode.dark,
                    onChanged: (v) => ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light,
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  theme, Icons.notifications_outlined, 'إعدادات التنبيهات',
                  onTap: () => context.push('/notifications'),
                  trailing: Icon(Icons.chevron_left, color: theme.colorScheme.outline),
                ),
                const Divider(height: 1, indent: 52),
                _settingsRow(
                  theme, Icons.alarm, 'تذكير بالتمارين',
                  onTap: () => _showSnack(context, 'سيتم إضافة خيار تذكير التمارين قريباً'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('30 دقيقة', style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, color: theme.colorScheme.outline),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'المعلومات',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.outline,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _settingsGroup(
              theme,
              children: [
                _settingsRow(theme, Icons.info_outline, 'عن التطبيق',
                  onTap: () => _showSnack(context, 'مركز الأهلي الرياضي'),
                  trailing: Icon(Icons.chevron_left, color: theme.colorScheme.outline)),
                const Divider(height: 1, indent: 52),
                _settingsRow(theme, Icons.policy_outlined, 'سياسة الخصوصية',
                  onTap: () => _showSnack(context, 'سياسة الخصوصية قيد التطوير'),
                  trailing: Icon(Icons.chevron_left, color: theme.colorScheme.outline)),
                const Divider(height: 1, indent: 52),
                _settingsRow(theme, Icons.help_outline, 'مركز المساعدة',
                  onTap: () => context.push('/help'),
                  trailing: Icon(Icons.chevron_left, color: theme.colorScheme.outline)),
              ],
            ),
            const SizedBox(height: 32),
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
            Center(
              child: Text(
                'مركز الأهلي الرياضي',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _settingsGroup(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsRow(
    ThemeData theme,
    IconData icon,
    String label, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
