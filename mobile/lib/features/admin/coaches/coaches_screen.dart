import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/staggered_list_item.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/models/user_model.dart';
import '../../../core/helpers/ui_helpers.dart';

class CoachesScreen extends ConsumerStatefulWidget {
  const CoachesScreen({super.key});

  @override
  ConsumerState<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends ConsumerState<CoachesScreen> {
  Future<void> _showAddTrainerDialog() async {
    final nameController = TextEditingController();
    final initialsController = TextEditingController();
    final roleController = TextEditingController();
    final expController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مدرب جديد', textAlign: TextAlign.right),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الأول (عربي)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: initialsController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الأخير (عربي)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: expController,
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: roleController,
                  textAlign: TextAlign.right,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('إضافة المدرب'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final data = {
          'first_name_ar': nameController.text.trim(),
          'last_name_ar': initialsController.text.trim(),
          'phone': expController.text.trim(),
          'password': roleController.text.trim(),
          'role': 'trainer',
          'is_active': true,
        };

        await ref.read(staffRepositoryProvider).createStaff(data);
        ref.invalidate(staffProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة المدرب بنجاح')),
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

  void _showTrainerDetails(UserModel coach) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
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
                    backgroundColor: AppColors.primary,
                    radius: 28,
                    backgroundImage: coach.photo != null && coach.photo!.isNotEmpty
                        ? NetworkImage(coach.photo!)
                        : null,
                    child: coach.photo == null || coach.photo!.isEmpty
                        ? Text(safeInitials(coach.firstNameAr), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.fullNameAr ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'مدرب',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('رقم الهاتف: ${coach.phone.toWesternDigits()}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Text('حالة الحساب: ${coach.isActive ? 'نشط' : 'غير نشط'}', style: TextStyle(fontSize: 14, color: coach.isActive ? Colors.teal : Colors.red)),
              const SizedBox(height: 24),
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

  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(staffProvider(const {'role': 'trainer'}));
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المدربين', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: user?.role == 'super_admin'
          ? FloatingActionButton(
              onPressed: _showAddTrainerDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(staffProvider),
        child: trainersAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(message: 'لا يوجد مدربون مسجلون حالياً');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final coach = list[index];

                return StaggeredListItem(
                  index: index,
                  child: AppCard(
                  onTap: () => _showTrainerDetails(coach),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5), // Match academy cards layout style
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 24,
                        backgroundImage: coach.photo != null && coach.photo!.isNotEmpty
                            ? NetworkImage(coach.photo!)
                            : null,
                        child: coach.photo == null || coach.photo!.isEmpty
                            ? Text(safeInitials(coach.firstNameAr), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coach.fullNameAr ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'مدرب',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
                );
              },
            );
          },
          loading: () => const ShimmerList(),
          error: (err, stack) => AppErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.refresh(staffProvider(const {'role': 'trainer'})),
          ),
        ),
      ),
    );
  }
}
