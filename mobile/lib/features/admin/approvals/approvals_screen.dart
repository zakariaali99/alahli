import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/paginated_providers.dart';
import '../../../core/providers/paginated_list_notifier.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/staggered_list_item.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/ui_helpers.dart';
import '../../../core/models/registration_model.dart';
import '../../../core/models/subscription_model.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveRegistration(RegistrationModel reg) async {
    try {
      await ref.read(registrationRepositoryProvider).approveRegistration(reg.id);
      ref.read(registrationsPaginatedProvider(RegistrationFilter(status: 'pending')).notifier).refresh();
      ref.invalidate(athletesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول طلب التسجيل بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rejectRegistration(RegistrationModel reg) async {
    try {
      await ref.read(registrationRepositoryProvider).rejectRegistration(reg.id);
      ref.read(registrationsPaginatedProvider(RegistrationFilter(status: 'pending')).notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض طلب التسجيل')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _approveSubscription(SubscriptionModel sub) async {
    try {
      await ref.read(subscriptionRepositoryProvider).updateSubscriptionStatus(sub.id, 'active');
      ref.read(subscriptionsPaginatedProvider(SubscriptionFilter(status: 'pending')).notifier).refresh();
      ref.invalidate(dashboardStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل الاشتراك وقبوله بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rejectSubscription(SubscriptionModel sub) async {
    try {
      await ref.read(subscriptionRepositoryProvider).updateSubscriptionStatus(sub.id, 'rejected');
      ref.read(subscriptionsPaginatedProvider(SubscriptionFilter(status: 'pending')).notifier).refresh();
      ref.invalidate(dashboardStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض طلب الاشتراك بنجاح وسيكون خارج الحسابات المالية')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    }
  }

  // Dialog to create athlete profile for pending registration request
  Future<void> _showCreateProfileDialog(RegistrationModel reg) async {
    final nameController = TextEditingController(text: reg.userName);
    final phoneController = TextEditingController(text: reg.userPhone);
    String selectedGender = 'male';
    int? selectedDeptId;
    DateTime? selectedDate;
    final birthDateController = TextEditingController();

    final user = ref.read(authProvider);
    final deptsAsync = ref.read(departmentsProvider);

    if (user?.role == 'academy_manager') {
      selectedDeptId = user?.academy;
    }

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('إنشاء الملف الرياضي للاعب', textAlign: TextAlign.right),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                        validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال الاسم' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                        validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: const InputDecoration(labelText: 'الجنس'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('ذكر')),
                          DropdownMenuItem(value: 'female', child: Text('أنثى')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDlgState(() => selectedGender = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: birthDateController,
                        readOnly: true,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(labelText: 'تاريخ الميلاد', prefixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2010),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDlgState(() {
                              selectedDate = date;
                              birthDateController.text = NumberFormatter.formatDate(date);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      if (user?.role != 'academy_manager')
                        deptsAsync.when(
                          data: (list) {
                            return DropdownButtonFormField<int?>(
                              value: selectedDeptId,
                              decoration: const InputDecoration(labelText: 'الأكاديمية/القسم'),
                              items: list.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nameAr))).toList(),
                              onChanged: (v) => setDlgState(() => selectedDeptId = v),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (selectedDate == null) return;
                    if (selectedDeptId == null) return;

                    final formattedBirth = DateFormat('yyyy-MM-dd').format(selectedDate!);

                    try {
                      final formData = FormData.fromMap({
                        'full_name': nameController.text.trim(),
                        'phone': phoneController.text.trim().toWesternDigits(),
                        'gender': selectedGender,
                        'birth_date': formattedBirth,
                        'department': selectedDeptId,
                        'is_active': false,
                      });

                      await ref.read(registrationRepositoryProvider).createAthleteProfile(
                            registrationId: reg.id,
                            formData: formData,
                          );

                      ref.read(registrationsPaginatedProvider(RegistrationFilter(status: 'pending')).notifier).refresh();
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('إنشاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRegistrationDetails(RegistrationModel reg) {
    final hasProfile = reg.athleteId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'تفاصيل طلب التسجيل',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: reg.roleChoice == 'athlete'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.secondary.withValues(alpha: 0.1),
                    backgroundImage: reg.athletePhoto != null ? NetworkImage(reg.athletePhoto!) : null,
                    child: reg.athletePhoto == null
                        ? Icon(
                            reg.roleChoice == 'athlete' ? Icons.person : Icons.supervisor_account,
                            color: reg.roleChoice == 'athlete' ? AppColors.primary : AppColors.secondary,
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reg.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الهاتف: ${reg.userPhone.toWesternDigits()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: reg.roleChoice == 'athlete'
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      reg.roleChoice == 'athlete' ? 'لاعب' : 'ولي أمر',
                      style: TextStyle(
                        color: reg.roleChoice == 'athlete' ? AppColors.primary : AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'تاريخ تقديم الطلب',
                value: safeDateTimeParse(reg.createdAt) != null
                    ? NumberFormatter.formatDateTime(safeDateTimeParse(reg.createdAt)!)
                    : reg.createdAt,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.business_outlined,
                label: 'القسم / الأكاديمية',
                value: reg.athleteDepartmentName ?? (reg.athleteId != null ? 'ملف مكتمل' : 'بحاجة لإنشاء ملف'),
              ),
              if (reg.athleteMembershipNumber != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.badge_outlined,
                  label: 'رقم العضوية',
                  value: reg.athleteMembershipNumber!.toWesternDigits(),
                ),
              ],
              if (reg.hasParent && reg.parentName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkMuted : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.supervisor_account, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'تمت الإضافة بواسطة ولي الأمر',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('الاسم: ${reg.parentName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('الهاتف: ${reg.parentPhone ?? ""}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (hasProfile && reg.athleteId != null) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/dashboard/athletes/${reg.athleteId}');
                  },
                  icon: const Icon(Icons.badge, size: 16),
                  label: const Text('عرض الملف الرياضي للاعب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _rejectRegistration(reg);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        side: const BorderSide(color: AppColors.destructive),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('رفض الطلب'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (reg.roleChoice == 'athlete' && !hasProfile)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCreateProfileDialog(reg);
                        },
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('إنشاء ملف لاعب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveRegistration(reg);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('اعتماد وقبول'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final regFilter = RegistrationFilter(status: 'pending');
    final subFilter = SubscriptionFilter(status: 'pending');

    final regState = ref.watch(registrationsPaginatedProvider(regFilter));
    final subState = ref.watch(subscriptionsPaginatedProvider(subFilter));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إدارة الموافقات والطلبات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: isDark ? Colors.white : Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
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
                      Tab(text: AppStrings.registrations),
                      Tab(text: AppStrings.pendingSubscriptions),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () => ref.read(registrationsPaginatedProvider(regFilter).notifier).refresh(),
                  child: _buildRegistrationsTab(regState),
                ),
                RefreshIndicator(
                  onRefresh: () => ref.read(subscriptionsPaginatedProvider(subFilter).notifier).refresh(),
                  child: _buildSubscriptionsTab(subState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationsTab(PaginatedListState<RegistrationModel> state) {
    if (state.state == PaginatedState.loading) {
      return const ShimmerList();
    }

    if (state.state == PaginatedState.error) {
      return AppErrorWidget(
        errorMessage: state.error ?? 'خطأ غير معروف',
        onRetry: () => ref.read(registrationsPaginatedProvider(RegistrationFilter(status: 'pending')).notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          EmptyState(message: 'لا توجد طلبات تسجيل جديدة بانتظار المراجعة'),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const SizedBox(height: 100);
        }
        final reg = state.items[index];
        final hasProfile = reg.athleteId != null;

        return StaggeredListItem(
          index: index,
          child: AppCard(
            onTap: () => _showRegistrationDetails(reg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reg.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: reg.roleChoice == 'athlete'
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reg.roleChoice == 'athlete' ? 'لاعب' : 'ولي أمر',
                        style: TextStyle(
                          color: reg.roleChoice == 'athlete' ? AppColors.primary : AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('الهاتف: ${reg.userPhone.toWesternDigits()}', style: const TextStyle(fontSize: 13)),
                Text('تاريخ الطلب: ${safeDateTimeParse(reg.createdAt) != null ? NumberFormatter.formatDateTime(safeDateTimeParse(reg.createdAt)!) : ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _rejectRegistration(reg),
                      child: const Text(AppStrings.reject, style: TextStyle(color: AppColors.destructive)),
                    ),
                    if (hasProfile && reg.athleteId != null)
                      TextButton.icon(
                        onPressed: () => context.push('/dashboard/athletes/${reg.athleteId}'),
                        icon: const Icon(Icons.badge, size: 16, color: AppColors.primary),
                        label: const Text('عرض الملف', style: TextStyle(color: AppColors.primary)),
                      ),
                    if (reg.roleChoice == 'athlete' && !hasProfile)
                      ElevatedButton.icon(
                        onPressed: () => _showCreateProfileDialog(reg),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('إنشاء الملف الرياضي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _approveRegistration(reg),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text(AppStrings.approve),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionsTab(PaginatedListState<SubscriptionModel> state) {
    if (state.state == PaginatedState.loading) {
      return const ShimmerList();
    }

    if (state.state == PaginatedState.error) {
      return AppErrorWidget(
        errorMessage: state.error ?? 'خطأ غير معروف',
        onRetry: () => ref.read(subscriptionsPaginatedProvider(SubscriptionFilter(status: 'pending')).notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          EmptyState(message: 'لا توجد طلبات اشتراك جديدة بانتظار التفعيل'),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const SizedBox(height: 100);
        }
        final sub = state.items[index];

        return StaggeredListItem(
          index: index,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sub.athleteName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '${NumberFormatter.formatCurrency(sub.amount)} د.ل',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('رقم العضوية: ${sub.membershipNumber.toWesternDigits()}', style: const TextStyle(fontSize: 13)),
                Text('الباقة: ${sub.packageName}', style: const TextStyle(fontSize: 13)),
                Text('الأكاديمية: ${sub.departmentName}', style: const TextStyle(fontSize: 13)),
                Text('طريقة الدفع: ${sub.paymentMethod == 'cash' ? 'نقدي' : 'تحويل مصرفي'}', style: const TextStyle(fontSize: 13)),
                if (sub.invoicePdfUrl != null && sub.invoicePdfUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(sub.invoicePdfUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.file_present_outlined, size: 16, color: AppColors.primary),
                    label: const Text('عرض إيصال التحويل (PDF/صورة)', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                ],
                const Divider(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _rejectSubscription(sub),
                      child: const Text(AppStrings.reject, style: TextStyle(color: AppColors.destructive)),
                    ),
                    ElevatedButton(
                      onPressed: () => _approveSubscription(sub),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text(AppStrings.approve),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
