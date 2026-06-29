import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/ui_helpers.dart';
import '../../../core/helpers/responsive_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _changePasswordFormKey = GlobalKey<FormState>();
  bool _isChangingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_changePasswordFormKey.currentState!.validate()) return;

    setState(() {
      _isChangingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
          );

      setState(() {
        _passwordSuccess = 'تم تغيير كلمة المرور بنجاح';
        _oldPasswordController.clear();
        _newPasswordController.clear();
      });
    } catch (e) {
      setState(() {
        _passwordError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'تأكيد تسجيل الخروج',
        content: 'هل أنت متأكد من تسجيل الخروج من حسابك؟',
        confirmLabel: 'خروج',
        confirmColor: AppColors.destructive,
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'super_admin':
        return 'مدير النظام الرئيسي';
      case 'academy_manager':
        return 'مدير أكاديمية';
      case 'reception':
        return 'موظف استقبال';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Meta Card
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: user?.photo != null ? NetworkImage(user!.photo!) : null,
                    child: user?.photo == null
                        ? Text(safeInitials(user?.firstNameAr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullNameAr ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRoleName(user?.role ?? ''),
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
                        ),
                        Text(
                          user?.phone.toWesternDigits() ?? '',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // More Menu Options List (Grid Layout)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'الوصول السريع للمهام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),

            GridView.count(
              crossAxisCount: ResponsiveHelper.isSmallPhone(context) ? 1 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: ResponsiveHelper.isSmallPhone(context) ? 3.5 : ResponsiveHelper.getGridAspectRatio(context, itemHeight: 80),
              children: [
                _buildQuickActionCard(Icons.credit_card, 'سجل الاشتراكات', '/subscriptions', context),
                _buildQuickActionCard(Icons.qr_code_scanner, 'الفحص والتحقق', '/verify', context),
                if (user?.role == 'super_admin') ...[
                  _buildQuickActionCard(Icons.business, 'الأكاديميات', '/academies', context),
                  _buildQuickActionCard(Icons.card_membership, 'الباقات', '/packages', context),
                  _buildQuickActionCard(Icons.sports, 'المدربين', '/coaches', context),
                  _buildQuickActionCard(Icons.admin_panel_settings, 'إدارة الموظفين', '/staff', context),
                ],
                _buildQuickActionCard(Icons.bar_chart, 'التقارير المالية', '/reports', context),
                _buildQuickActionCard(Icons.notifications_active, 'التنبيهات', '/notifications', context),
              ],
            ),

            const SizedBox(height: 20),

            // Change Password Form Card
            AppCard(
              child: Form(
                key: _changePasswordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'تغيير كلمة المرور',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                    const Divider(height: 20),
                    if (_passwordError != null) ...[
                      Text(_passwordError!, style: const TextStyle(color: AppColors.destructive, fontSize: 12), textAlign: TextAlign.right),
                      const SizedBox(height: 8),
                    ],
                    if (_passwordSuccess != null) ...[
                      Text(_passwordSuccess!, style: const TextStyle(color: AppColors.secondary, fontSize: 12), textAlign: TextAlign.right),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'كلمة المرور الحالية', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      validator: (v) => v == null || v.isEmpty ? 'حقل مطلوب' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      validator: (v) => v == null || v.length < 8 ? 'يجب أن لا تقل عن 8 خانات' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isChangingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isChangingPassword
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('تحديث كلمة المرور'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logout Card
            AppCard(
              onTap: _handleLogout,
              color: AppColors.destructive.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppColors.destructive),
                  SizedBox(width: 12),
                  Text(
                    'تسجيل الخروج من الحساب',
                    style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, String route, BuildContext context) {
    return AppCard(
      onTap: () => context.push(route),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
