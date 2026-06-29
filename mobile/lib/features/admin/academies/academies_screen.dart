import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/ui_helpers.dart';
import '../../../core/models/department_model.dart';

class AcademiesScreen extends ConsumerStatefulWidget {
  const AcademiesScreen({super.key});

  @override
  ConsumerState<AcademiesScreen> createState() => _AcademiesScreenState();
}

class _AcademiesScreenState extends ConsumerState<AcademiesScreen> {
  Future<void> _showAddAcademyDialog() async {
    final nameController = TextEditingController();
    final nameArController = TextEditingController();
    final bankController = TextEditingController();
    final ibanController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة أكاديمية جديدة', textAlign: TextAlign.right),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'الاسم بالإنجليزية',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameArController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'الاسم بالعربية',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bankController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'رقم الحساب البنكي',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ibanController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'رقم الآيبان (IBAN)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
            child: const Text('إضافة الأكاديمية'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final formData = FormData.fromMap({
          'name': nameController.text.trim(),
          'name_ar': nameArController.text.trim(),
          'bank_account_number': bankController.text.trim(),
          'iban': ibanController.text.trim(),
          'color': '#1487D4',
        });

        await ref.read(departmentRepositoryProvider).createDepartment(formData);
        ref.invalidate(departmentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الأكاديمية بنجاح')),
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

  void _showAcademyDetails(DepartmentModel dept) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: safeColor(dept.color),
                    radius: 20,
                    child: Text(
                      safeInitials(dept.nameAr),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    dept.nameAr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('رقم الحساب البنكي للتسديد: ${dept.bankAccountNumber.toWesternDigits()}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text('رقم الآيبان (IBAN): ${dept.iban.toWesternDigits()}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأكاديميات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: user?.role == 'super_admin'
          ? FloatingActionButton(
              onPressed: _showAddAcademyDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(departmentsProvider),
        child: departmentsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(message: 'لا توجد أكاديميات مسجلة');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final dept = list[index];
                final color = safeColor(dept.color);

                return AppCard(
                  onTap: () => _showAcademyDetails(dept),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color,
                        radius: 24,
                        backgroundImage: dept.logo != null ? NetworkImage(dept.logo!) : null,
                        child: dept.logo == null
                            ? Text(safeInitials(dept.nameAr), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dept.nameAr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'رقم الحساب: ${dept.bankAccountNumber.isEmpty ? "غير محدد" : dept.bankAccountNumber.toWesternDigits()}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const ShimmerList(),
          error: (err, stack) => AppErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.refresh(departmentsProvider),
          ),
        ),
      ),
    );
  }
}
