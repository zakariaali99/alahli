import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/helpers/ui_helpers.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/models/user_model.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRoleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getFilterParams() {
    return {
      'search': _searchQuery,
      'role': _selectedRoleFilter,
    };
  }

  Future<void> _showAddStaffDialog() async {
    final phoneController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'reception';
    int? selectedAcademyId;
    final formKey = GlobalKey<FormState>();

    final deptsAsync = ref.read(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('إضافة موظف/مدير جديد', textAlign: TextAlign.right),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'الاسم الأول بالعربية'),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: lastNameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'اسم العائلة بالعربية'),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'كلمة المرور (8 خانات على الأقل)'),
                    validator: (v) => v == null || v.length < 8 ? 'يجب أن لا تقل عن 8 خانات' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'الصلاحية / الدور'),
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'super_admin', child: Text('مدير النظام الرئيسي')),
                      DropdownMenuItem(value: 'academy_manager', child: Text('مدير أكاديمية')),
                      DropdownMenuItem(value: 'reception', child: Text('موظف استقبال')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDlgState(() {
                          selectedRole = v;
                          if (selectedRole != 'academy_manager') {
                            selectedAcademyId = null;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  if (selectedRole == 'academy_manager')
                    deptsAsync.when(
                      data: (list) {
                        return DropdownButtonFormField<int?>(
                          value: selectedAcademyId,
                          decoration: const InputDecoration(labelText: 'تخصيص للأكاديمية'),
                          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                          items: list.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nameAr))).toList(),
                          onChanged: (v) => setDlgState(() => selectedAcademyId = v),
                          validator: (v) => v == null ? 'يجب اختيار الأكاديمية لمدير الأكاديمية' : null,
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
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إضافة حساب'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      if (!formKey.currentState!.validate()) return;
      try {
        final data = {
          'first_name_ar': firstNameController.text.trim(),
          'last_name_ar': lastNameController.text.trim(),
          'phone': phoneController.text.trim().toWesternDigits(),
          'password': passwordController.text,
          'role': selectedRole,
          'academy': selectedAcademyId,
          'is_active': true,
        };

        await ref.read(staffRepositoryProvider).createStaff(data);
        ref.invalidate(staffProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الموظف/المدير بنجاح')),
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
  }

  Future<void> _deleteStaff(UserModel staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: 'تأكيد حذف الحساب',
        content: 'هل أنت متأكد من حذف حساب الموظف ${staff.fullNameAr} نهائياً؟ لن يتمكن من الدخول للنظام بعد الآن.',
        confirmLabel: 'حذف الحساب',
        confirmColor: AppColors.destructive,
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(staffRepositoryProvider).deleteStaff(staff.id);
        ref.invalidate(staffProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف حساب الموظف بنجاح')),
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
  }

  String _getRoleLabel(String role) {
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
    final filter = _getFilterParams();
    final staffAsync = ref.watch(staffProvider(filter));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الكادر الإداري والموظفين', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStaffDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'بحث باسم الموظف أو رقم الهاتف...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('الكل'),
                        selected: _selectedRoleFilter == null,
                        onSelected: (val) => setState(() => _selectedRoleFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('مدراء الأقسام'),
                        selected: _selectedRoleFilter == 'academy_manager',
                        onSelected: (val) => setState(() => _selectedRoleFilter = val ? 'academy_manager' : null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('الاستقبال'),
                        selected: _selectedRoleFilter == 'reception',
                        onSelected: (val) => setState(() => _selectedRoleFilter = val ? 'reception' : null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(staffProvider(filter)),
              child: staffAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(message: 'لا يوجد موظفون يطابقون شروط البحث');
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final staff = list[index];

                      return AppCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: staff.photo != null ? NetworkImage(staff.photo!) : null,
                              child: staff.photo == null
                                   ? Text(safeInitials(staff.firstNameAr), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(staff.fullNameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('الهاتف: ${staff.phone.toWesternDigits()}', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getRoleLabel(staff.role),
                                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (staff.academyName != null && staff.academyName!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            staff.academyName!,
                                            style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              color: isDark ? AppColors.darkCard : Colors.white,
                              onSelected: (val) {
                                if (val == 'delete') {
                                  _deleteStaff(staff);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('حذف الحساب', style: TextStyle(color: AppColors.destructive)),
                                      SizedBox(width: 8),
                                      Icon(Icons.delete_forever, color: AppColors.destructive, size: 18),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const ShimmerList(),
                error: (err, stack) => AppErrorWidget(
                  errorMessage: err.toString(),
                  onRetry: () => ref.refresh(staffProvider(filter)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
