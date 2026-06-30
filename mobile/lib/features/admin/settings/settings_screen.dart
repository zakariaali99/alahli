import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/ui_helpers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _changePasswordFormKey = GlobalKey<FormState>();
  bool _isChangingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  // Appearance states
  bool _darkMode = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final prefs = ref.watch(preferencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Premium Styled Tab Bar
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: isDark ? Colors.white : Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    tabs: const [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person, size: 16), SizedBox(width: 4), Text('الحساب', style: TextStyle(fontSize: 11))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications, size: 16), SizedBox(width: 4), Text('الإشعارات', style: TextStyle(fontSize: 11))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.security, size: 16), SizedBox(width: 4), Text('الأمان', style: TextStyle(fontSize: 11))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.palette, size: 16), SizedBox(width: 4), Text('المظهر', style: TextStyle(fontSize: 11))])),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Profile Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: user?.photo != null ? NetworkImage(user!.photo!) : null,
                              child: user?.photo == null
                                  ? Text(safeInitials(user?.firstNameAr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24))
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?.fullNameAr ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getRoleName(user?.role ?? ''),
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProfileField('الاسم الأول', user?.firstNameAr ?? '—', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildProfileField('اسم العائلة', user?.lastNameAr ?? '—', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildProfileField('رقم الهاتف', user?.phone.toWesternDigits() ?? '—', Icons.phone_outlined),
                      const SizedBox(height: 12),
                      _buildProfileField('مستوى الصلاحية', _getRoleName(user?.role ?? ''), Icons.shield_outlined),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // 2. Notifications Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'تفضيلات تنبيهات النظام',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildNotificationToggle(
                        title: 'انتهاء الاشتراكات',
                        subtitle: 'تنبيه عند اقتراب موعد انتهاء اشتراك أي لاعب',
                        icon: Icons.warning_amber_rounded,
                        value: prefs?.notificationsEnabled ?? true,
                        onChanged: (val) {
                          ref.read(preferencesProvider.notifier).updatePreference(notificationsEnabled: val);
                        },
                      ),
                      _buildNotificationToggle(
                        title: 'التسجيلات الجديدة',
                        subtitle: 'تنبيه عند تسجيل لاعب جديد في النظام',
                        icon: Icons.person_add_outlined,
                        value: prefs?.notificationsEnabled ?? true,
                        onChanged: (val) {
                          ref.read(preferencesProvider.notifier).updatePreference(notificationsEnabled: val);
                        },
                      ),
                      _buildNotificationToggle(
                        title: 'المدفوعات والتأكيدات',
                        subtitle: 'تنبيه عبر البريد عند تأكيد عملية دفع أو تجديد',
                        icon: Icons.credit_card_outlined,
                        value: prefs?.emailEnabled ?? true,
                        onChanged: (val) {
                          ref.read(preferencesProvider.notifier).updatePreference(emailEnabled: val);
                        },
                      ),
                      _buildNotificationToggle(
                        title: 'أمان وتحديثات النظام',
                        subtitle: 'تلقي رسائل نصية قصيرة عند التحديثات الهامة',
                        icon: Icons.security_update_warning_outlined,
                        value: prefs?.smsEnabled ?? true,
                        onChanged: (val) {
                          ref.read(preferencesProvider.notifier).updatePreference(smsEnabled: val);
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // 3. Security Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Form(
                          key: _changePasswordFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'تغيير كلمة المرور',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
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
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: true,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                validator: (v) => v == null || v.length < 8 ? 'يجب أن لا تقل عن 8 خانات' : null,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _isChangingPassword ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // 4. Appearance Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAppearanceToggle(
                        title: 'الوضع الداكن',
                        subtitle: 'تفعيل المظهر الداكن لتسهيل الرؤية الليلية',
                        icon: Icons.dark_mode_outlined,
                        value: _darkMode,
                        onChanged: (val) {
                          setState(() {
                            _darkMode = val;
                          });
                        },
                      ),
                      _buildAppearanceToggle(
                        title: 'تقليل الحركة',
                        subtitle: 'إيقاف تأثيرات الحركة الانتقالية وتسريع التنقل',
                        icon: Icons.motion_photos_off_outlined,
                        value: _reduceMotion,
                        onChanged: (val) {
                          setState(() {
                            _reduceMotion = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'تطبيق وحفظ التفضيلات تلقائياً',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'يتم حفظ خيارات المظهر وإعدادات التنبيهات في قاعدة بيانات حسابك لتستفيد منها على كافة الأجهزة.',
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }
}
