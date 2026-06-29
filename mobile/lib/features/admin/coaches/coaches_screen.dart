import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/models/trainer_model.dart';

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
                  decoration: const InputDecoration(labelText: 'الاسم الكامل للمدرب'),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: initialsController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الحروف الأولى (مثال: أ.م)'),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: roleController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'التخصص/الدور'),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: expController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'سنوات الخبرة'),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
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
            child: const Text('إضافة المدرب'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final data = {
          'full_name_ar': nameController.text.trim(),
          'initials': initialsController.text.trim(),
          'role': roleController.text.trim(),
          'experience_years': int.parse(expController.text.trim().toWesternDigits()),
          'rating': 0.0,
          'reviews_count': 0,
        };

        await ref.read(trainerRepositoryProvider).createTrainer(data);
        ref.invalidate(trainersProvider);
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

  void _showTrainerDetails(TrainerModel coach) {
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
                    backgroundImage: coach.profileImage != null && coach.profileImage!.isNotEmpty
                        ? NetworkImage(coach.profileImage!)
                        : null,
                    child: coach.profileImage == null || coach.profileImage!.isEmpty
                        ? Text(coach.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.fullNameAr,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          coach.role,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('سنوات الخبرة: ${coach.experienceYears.toString().toWesternDigits()}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('التقييم: ', style: TextStyle(fontSize: 14)),
                  const Icon(Icons.star, color: AppColors.gold, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${coach.rating.toString().toWesternDigits()} (${coach.reviewsCount.toString().toWesternDigits()} مراجعة)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (coach.bio != null && coach.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('نبذة تعريفية: ${coach.bio}', style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
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

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(trainersProvider);
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
        onRefresh: () async => ref.invalidate(trainersProvider),
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

                return AppCard(
                  onTap: () => _showTrainerDetails(coach),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5), // Match academy cards layout style
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 24,
                        backgroundImage: coach.profileImage != null && coach.profileImage!.isNotEmpty
                            ? NetworkImage(coach.profileImage!)
                            : null,
                        child: coach.profileImage == null || coach.profileImage!.isEmpty
                            ? Text(coach.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coach.fullNameAr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              coach.role,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.gold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            coach.rating.toString().toWesternDigits(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
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
            onRetry: () => ref.refresh(trainersProvider),
          ),
        ),
      ),
    );
  }
}
