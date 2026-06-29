import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/ui_helpers.dart';
import 'package:intl/intl.dart';
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
      ref.invalidate(registrationsProvider);
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
      ref.invalidate(registrationsProvider);
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
      ref.invalidate(subscriptionsProvider);
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
      ref.invalidate(subscriptionsProvider);
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
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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

                      ref.invalidate(registrationsProvider);
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    final Map<String, dynamic> regParams = {'status': 'pending'};
    final Map<String, dynamic> subParams = {'status': 'pending'};

    if (user?.role == 'academy_manager') {
      subParams['departmentId'] = user?.academy;
    }

    final registrationsAsync = ref.watch(registrationsProvider(regParams));
    final subscriptionsAsync = ref.watch(subscriptionsProvider(subParams));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموافقات والطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: AppStrings.registrations),
            Tab(text: AppStrings.pendingSubscriptions),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Registrations Tab
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(registrationsProvider(regParams)),
            child: registrationsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(message: 'لا توجد طلبات تسجيل جديدة بانتظار المراجعة');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final reg = list[index];
                    final hasProfile = reg.athleteId != null;

                    return AppCard(
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
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.secondary.withOpacity(0.1),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _rejectRegistration(reg),
                                child: const Text(AppStrings.reject, style: TextStyle(color: AppColors.destructive)),
                              ),
                              const SizedBox(width: 12),
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
                    );
                  },
                );
              },
              loading: () => const ShimmerList(),
              error: (err, stack) => AppErrorWidget(
                errorMessage: err.toString(),
                onRetry: () => ref.refresh(registrationsProvider(regParams)),
              ),
            ),
          ),

          // Subscriptions Tab
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(subscriptionsProvider(subParams)),
            child: subscriptionsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(message: 'لا توجد طلبات اشتراك جديدة بانتظار التفعيل');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final sub = list[index];

                    return AppCard(
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
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _rejectSubscription(sub),
                                child: const Text(AppStrings.reject, style: TextStyle(color: AppColors.destructive)),
                              ),
                              const SizedBox(width: 12),
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
                    );
                  },
                );
              },
              loading: () => const ShimmerList(),
              error: (err, stack) => AppErrorWidget(
                errorMessage: err.toString(),
                onRetry: () => ref.refresh(subscriptionsProvider(subParams)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
