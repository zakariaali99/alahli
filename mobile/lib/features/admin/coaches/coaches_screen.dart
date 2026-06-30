import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_bottom_sheet.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/staggered_list_item.dart';
import '../../../core/models/trainer_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/helpers/ui_helpers.dart';
import '../../../core/helpers/numeral_converter.dart';

class CoachesScreen extends ConsumerStatefulWidget {
  const CoachesScreen({super.key});

  @override
  ConsumerState<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends ConsumerState<CoachesScreen> {
  TrainerModel? _selectedCoach;
  bool _showingDetails = false;
  List<GroupModel> _coachGroups = [];
  bool _loadingGroups = false;

  void _onCoachTap(TrainerModel coach) async {
    setState(() {
      _selectedCoach = coach;
      _showingDetails = true;
      _loadingGroups = true;
      _coachGroups = [];
    });
    try {
      final groups = await ref.read(trainerRepositoryProvider).fetchTrainerGroups(coach.id);
      if (mounted && _selectedCoach?.id == coach.id) {
        setState(() {
          _coachGroups = groups;
          _loadingGroups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingGroups = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المجموعات: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(StateSetter setState, File? currentImage, Function(File?) onImagePicked) async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر مصدر الصورة', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('الكاميرا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('المعرض'),
          ),
        ],
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        onImagePicked(File(picked.path));
      }
    }
  }

  Future<void> _showAddEditCoachDialog([TrainerModel? coach]) async {
    final firstNameController = TextEditingController(text: coach?.firstNameAr ?? '');
    final lastNameController = TextEditingController(text: coach?.lastNameAr ?? '');
    final phoneController = TextEditingController(text: coach?.phone ?? '');
    final passwordController = TextEditingController();
    bool isActive = coach?.isActive ?? true;
    File? selectedImage;
    bool submitting = false;

    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: PinnedBottomSheet(
          title: coach == null ? 'إضافة مدرب جديد' : 'تعديل بيانات المدرب',
          submitLabel: coach == null ? 'إضافة المدرب' : 'حفظ التعديلات',
          onSubmit: () async {
            if (submitting) return;
            if (!formKey.currentState!.validate()) return;
            submitting = true;
            try {
              final map = {
                'first_name_ar': firstNameController.text.trim(),
                'last_name_ar': lastNameController.text.trim(),
                'phone': phoneController.text.trim().toWesternDigits(),
                'role': 'trainer',
                'is_active': isActive,
              };
              if (passwordController.text.isNotEmpty) {
                map['password'] = passwordController.text;
              }
              if (selectedImage != null) {
                map['photo'] = await MultipartFile.fromFile(selectedImage!.path);
              }
              if (!context.mounted) return;
              final formData = FormData.fromMap(map);

              if (coach == null) {
                await ref.read(trainerRepositoryProvider).createTrainer(formData);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إضافة المدرب بنجاح')),
                );
              } else {
                await ref.read(trainerRepositoryProvider).updateTrainer(coach.id, formData);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث المدرب بنجاح')),
                );
              }
              ref.invalidate(trainersProvider);
              Navigator.pop(ctx);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            } finally {
              submitting = false;
            }
          },
          body: StatefulBuilder(
            builder: (context, setDlgState) => Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Selection
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : (coach?.profileImage != null && coach!.profileImage!.isNotEmpty
                                  ? NetworkImage(coach.profileImage!) as ImageProvider
                                  : null),
                          child: (selectedImage == null && (coach?.profileImage == null || coach!.profileImage!.isEmpty))
                              ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _pickImage(setDlgState, selectedImage, (file) {
                              setDlgState(() => selectedImage = file);
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: lastNameController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            labelText: 'اللقب / العائلة',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: firstNameController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            labelText: 'الاسم الأول',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: coach == null ? 'كلمة المرور' : 'كلمة المرور الجديدة (اختياري)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      helperText: coach == null ? 'مطلوب للمدرب الجديد' : 'اتركه فارغاً للاحتفاظ بكلمة المرور القديمة',
                    ),
                    validator: (v) {
                      if (coach == null && (v == null || v.trim().isEmpty)) {
                        return 'مطلوب';
                      }
                      if (v != null && v.isNotEmpty && v.length < 8) {
                        return 'كلمة المرور يجب أن لا تقل عن 8 خانات';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('الحساب نشط ويستطيع الدخول', textAlign: TextAlign.right),
                    value: isActive,
                    onChanged: (val) => setDlgState(() => isActive = val),
                    activeColor: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(trainersProvider);
    final user = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: (user?.role == 'super_admin' && !_showingDetails)
          ? FloatingActionButton(
              onPressed: () => _showAddEditCoachDialog(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: PopScope(
        canPop: !_showingDetails,
        onPopInvokedWithResult: (didPop, result) {
          if (_showingDetails) {
            setState(() {
              _showingDetails = false;
              _selectedCoach = null;
            });
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showingDetails ? _buildDetailsView(isDark) : _buildListView(trainersAsync, user?.role, isDark),
        ),
      ),
    );
  }

  Widget _buildListView(AsyncValue<List<TrainerModel>> trainersAsync, String? role, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المدربون',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (role == 'super_admin')
                OutlinedButton.icon(
                  onPressed: () => _showAddEditCoachDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('إضافة مدرب'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(trainersProvider),
            child: trainersAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(message: 'لا يوجد مدربون مسجلون حالياً');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length + 1,
                  itemBuilder: (context, index) {
                    if (index == list.length) {
                      return const SizedBox(height: 120); // bottom spacing
                    }
                    final coach = list[index];

                    return StaggeredListItem(
                      index: index,
                      child: AppCard(
                        onTap: () => _onCoachTap(coach),
                        border: Border.all(
                          color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              radius: 24,
                              backgroundImage: coach.profileImage != null && coach.profileImage!.isNotEmpty
                                  ? NetworkImage(coach.profileImage!)
                                  : null,
                              child: coach.profileImage == null || coach.profileImage!.isEmpty
                                  ? Text(
                                      safeInitials(coach.fullNameAr),
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    )
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
                                    coach.phone.toWesternDigits(),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: coach.isActive
                                        ? AppColors.secondary.withValues(alpha: 0.15)
                                        : AppColors.destructive.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    coach.isActive ? 'نشط' : 'موقوف',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: coach.isActive ? AppColors.secondary : AppColors.destructive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_left, color: Colors.grey),
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
                onRetry: () => ref.refresh(trainersProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsView(bool isDark) {
    final coach = _selectedCoach!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation / Breadcrumb Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    _showingDetails = false;
                    _selectedCoach = null;
                  });
                },
              ),
              const Text(
                'المدربون',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
              Text(
                coach.fullNameAr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile Card
          AppCard(
            border: Border.all(
              color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: coach.profileImage != null && coach.profileImage!.isNotEmpty
                          ? NetworkImage(coach.profileImage!)
                          : null,
                      child: coach.profileImage == null || coach.profileImage!.isEmpty
                          ? Text(
                              safeInitials(coach.fullNameAr),
                              style: const TextStyle(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coach.fullNameAr,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coach.phone.toWesternDigits(),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: coach.isActive
                                  ? AppColors.secondary.withValues(alpha: 0.15)
                                  : AppColors.destructive.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              coach.isActive ? 'حساب نشط' : 'حساب موقوف',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: coach.isActive ? AppColors.secondary : AppColors.destructive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الصلاحية في النظام:', style: TextStyle(color: Colors.grey)),
                    Text(coach.role == 'trainer' ? 'مدرب رياضي' : coach.role, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showAddEditCoachDialog(coach),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل الحساب'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Assigned Groups Section
          const Text(
            'المجموعات الرياضية المسندة إليه',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _loadingGroups
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : _coachGroups.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: const Center(
                        child: Text(
                          'لا توجد مجموعات مسندة لهذا المدرب حالياً.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _coachGroups.length,
                      itemBuilder: (ctx, idx) {
                        final g = _coachGroups[idx];
                        return AppCard(
                          border: Border.all(
                            color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.nameAr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'الرياضة: ${g.sportName}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'الأيام: ${g.days.join("، ")}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'التوقيت: ${g.startTime.toWesternDigits()} - ${g.endTime.toWesternDigits()}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          const SizedBox(height: 120), // bottom spacing
        ],
      ),
    );
  }
}
