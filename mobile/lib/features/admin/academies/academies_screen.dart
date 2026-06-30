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
import '../../../core/models/sport_model.dart';
import '../../../core/models/group_model.dart';

enum AcademyStage { academies, sports, groups }

class AcademiesScreen extends ConsumerStatefulWidget {
  const AcademiesScreen({super.key});

  @override
  ConsumerState<AcademiesScreen> createState() => _AcademiesScreenState();
}

class _AcademiesScreenState extends ConsumerState<AcademiesScreen> {
  AcademyStage _stage = AcademyStage.academies;
  DepartmentModel? _selectedAcademy;
  SportModel? _selectedSport;

  List<SportModel> _sports = [];
  List<GroupModel> _groups = [];
  bool _loadingDetails = false;
  String? _detailsError;

  final List<Map<String, String>> _weekDays = [
    {'value': 'saturday', 'label': 'السبت'},
    {'value': 'sunday', 'label': 'الأحد'},
    {'value': 'monday', 'label': 'الإثنين'},
    {'value': 'tuesday', 'label': 'الثلاثاء'},
    {'value': 'wednesday', 'label': 'الأربعاء'},
    {'value': 'thursday', 'label': 'الخميس'},
    {'value': 'friday', 'label': 'الجمعة'},
  ];

  Future<void> _fetchSports(int academyId) async {
    setState(() {
      _loadingDetails = true;
      _detailsError = null;
    });
    try {
      final list = await ref.read(departmentRepositoryProvider).fetchSportsByDepartment(academyId);
      setState(() {
        _sports = list;
        _loadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _detailsError = e.toString();
        _loadingDetails = false;
      });
    }
  }

  Future<void> _fetchGroups(int sportId) async {
    setState(() {
      _loadingDetails = true;
      _detailsError = null;
    });
    try {
      final list = await ref.read(departmentRepositoryProvider).fetchGroupsBySport(sportId);
      setState(() {
        _groups = list;
        _loadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _detailsError = e.toString();
        _loadingDetails = false;
      });
    }
  }

  // --- ACADEMY CRUD ---
  Future<void> _showAddEditAcademyDialog([DepartmentModel? academy]) async {
    final nameController = TextEditingController(text: academy?.name ?? '');
    final nameArController = TextEditingController(text: academy?.nameAr ?? '');
    final bankController = TextEditingController(text: academy?.bankAccountNumber ?? '');
    final ibanController = TextEditingController(text: academy?.iban ?? '');
    final colorController = TextEditingController(text: academy?.color ?? '#1570EF');
    final formKey = GlobalKey<FormState>();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                academy == null ? 'إضافة أكاديمية جديدة' : 'تعديل الأكاديمية',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nameArController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'الاسم بالعربية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'الاسم بالإنجليزية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: colorController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'اللون (Hex)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(academy == null ? 'إضافة' : 'حفظ'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        final formData = FormData.fromMap({
          'name': nameController.text.trim(),
          'name_ar': nameArController.text.trim(),
          'bank_account_number': bankController.text.trim(),
          'iban': ibanController.text.trim(),
          'color': colorController.text.trim(),
        });

        if (academy == null) {
          await ref.read(departmentRepositoryProvider).createDepartment(formData);
        } else {
          await ref.read(departmentRepositoryProvider).updateDepartment(academy.id, formData);
        }
        ref.invalidate(departmentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(academy == null ? 'تم إضافة الأكاديمية بنجاح' : 'تم تحديث الأكاديمية')),
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

  // --- SPORT CRUD ---
  Future<void> _showAddEditSportDialog([SportModel? sport]) async {
    final nameController = TextEditingController(text: sport?.name ?? '');
    final nameArController = TextEditingController(text: sport?.nameAr ?? '');
    final formKey = GlobalKey<FormState>();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sport == null ? 'إضافة رياضة جديدة' : 'تعديل الرياضة',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameArController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'الاسم بالعربية',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'الاسم بالإنجليزية',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(sport == null ? 'إضافة' : 'حفظ'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        final data = {
          'name': nameController.text.trim(),
          'name_ar': nameArController.text.trim(),
          'department': _selectedAcademy!.id,
          'is_active': true,
        };

        if (sport == null) {
          await ref.read(departmentRepositoryProvider).createSport(data);
        } else {
          await ref.read(departmentRepositoryProvider).updateSport(sport.id, data);
        }
        await _fetchSports(_selectedAcademy!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sport == null ? 'تم إضافة الرياضة بنجاح' : 'تم تحديث الرياضة')),
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

  // --- GROUP CRUD ---
  Future<void> _showAddEditGroupDialog([GroupModel? group]) async {
    final nameController = TextEditingController(text: group?.name ?? '');
    final nameArController = TextEditingController(text: group?.nameAr ?? '');
    final startTimeController = TextEditingController(text: group?.startTime ?? '16:00');
    final endTimeController = TextEditingController(text: group?.endTime ?? '17:00');
    int? selectedCoachId = group?.coachId;
    List<String> selectedDays = List<String>.from(group?.days ?? []);
    final formKey = GlobalKey<FormState>();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final trainersAsync = ref.watch(trainersProvider);
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        group == null ? 'إضافة مجموعة جديدة' : 'تعديل المجموعة',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameArController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'الاسم بالعربية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'الاسم بالإنجليزية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      trainersAsync.when(
                        data: (list) {
                          return DropdownButtonFormField<int?>(
                            value: selectedCoachId,
                            decoration: InputDecoration(
                              labelText: 'المدرب',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('بدون مدرب')),
                              ...list.map((c) => DropdownMenuItem(value: c.id, child: Text(c.fullNameAr))),
                            ],
                            onChanged: (v) => setDlgState(() => selectedCoachId = v),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, s) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: startTimeController,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'وقت البداية',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: endTimeController,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'وقت النهاية',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'أيام التدريب',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _weekDays.map((day) {
                          final isChecked = selectedDays.contains(day['value']);
                          return FilterChip(
                            label: Text(day['label']!),
                            selected: isChecked,
                            onSelected: (val) {
                              setDlgState(() {
                                if (val) {
                                  selectedDays.add(day['value']!);
                                } else {
                                  selectedDays.remove(day['value']!);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                if (selectedDays.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('يرجى اختيار يوم واحد على الأقل')),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx, true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(group == null ? 'إضافة' : 'حفظ'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirm == true) {
      try {
        final data = {
          'name': nameController.text.trim(),
          'name_ar': nameArController.text.trim(),
          'sport': _selectedSport!.id,
          'coach': selectedCoachId,
          'start_time': startTimeController.text.trim(),
          'end_time': endTimeController.text.trim(),
          'days': selectedDays,
          'is_active': true,
        };

        if (group == null) {
          await ref.read(departmentRepositoryProvider).createGroup(data);
        } else {
          await ref.read(departmentRepositoryProvider).updateGroup(group.id, data);
        }
        await _fetchGroups(_selectedSport!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(group == null ? 'تم إضافة المجموعة بنجاح' : 'تم تحديث المجموعة')),
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

  // --- DELETE CONFIRMATION ---
  Future<void> _showDeleteConfirmDialog({
    required String title,
    required String name,
    required VoidCallback onDelete,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text('هل أنت متأكد من حذف "$name"؟ لا يمكن التراجع عن هذا الإجراء.', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onDelete();
    }
  }

  void _onAcademyTapped(DepartmentModel academy) async {
    setState(() {
      _selectedAcademy = academy;
      _selectedSport = null;
      _stage = AcademyStage.sports;
    });
    await _fetchSports(academy.id);
  }

  void _onSportTapped(SportModel sport) async {
    setState(() {
      _selectedSport = sport;
      _stage = AcademyStage.groups;
    });
    await _fetchGroups(sport.id);
  }

  // --- BREADCRUMBS ---
  Widget _buildBreadcrumbs() {
    if (_stage == AcademyStage.academies) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _stage = AcademyStage.academies;
                _selectedAcademy = null;
                _selectedSport = null;
              });
            },
            child: const Text(
              'الأكاديميات',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          if (_selectedAcademy != null) ...[
            const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
            InkWell(
              onTap: () {
                if (_stage == AcademyStage.groups) {
                  setState(() {
                    _stage = AcademyStage.sports;
                    _selectedSport = null;
                  });
                  _fetchSports(_selectedAcademy!.id);
                }
              },
              child: Text(
                _selectedAcademy!.nameAr,
                style: TextStyle(
                  color: _stage == AcademyStage.sports ? Colors.grey : AppColors.primary,
                  fontWeight: _stage == AcademyStage.sports ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          if (_selectedSport != null && _stage == AcademyStage.groups) ...[
            const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
            Text(
              _selectedSport!.nameAr,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: user?.role == 'super_admin'
          ? FloatingActionButton(
              onPressed: () {
                if (_stage == AcademyStage.academies) {
                  _showAddEditAcademyDialog();
                } else if (_stage == AcademyStage.sports) {
                  _showAddEditSportDialog();
                } else {
                  _showAddEditGroupDialog();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _stage == AcademyStage.academies
                      ? 'إدارة الأكاديميات'
                      : _stage == AcademyStage.sports
                          ? 'رياضات ${_selectedAcademy!.nameAr}'
                          : 'مجموعات ${_selectedSport!.nameAr}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildBreadcrumbs(),
          Expanded(
            child: _stage == AcademyStage.academies
                ? RefreshIndicator(
                    onRefresh: () async => ref.refresh(departmentsProvider),
                    child: departmentsAsync.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return const EmptyState(message: 'لا توجد أكاديميات مسجلة');
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length + 1, // spacing
                          itemBuilder: (context, index) {
                            if (index == list.length) return const SizedBox(height: 100);
                            final dept = list[index];
                            final color = safeColor(dept.color);

                            return AppCard(
                              onTap: () => _onAcademyTapped(dept),
                              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
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
                                  if (user?.role == 'super_admin') ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                      onPressed: () => _showAddEditAcademyDialog(dept),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _showDeleteConfirmDialog(
                                        title: 'تأكيد حذف الأكاديمية',
                                        name: dept.nameAr,
                                        onDelete: () async {
                                          try {
                                            await ref.read(departmentRepositoryProvider).deleteDepartment(dept.id);
                                            ref.invalidate(departmentsProvider);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('خطأ: ${e.toString()}')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                  const Icon(Icons.chevron_left, color: Colors.grey),
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
                  )
                : _loadingDetails
                    ? const ShimmerList()
                    : _detailsError != null
                        ? AppErrorWidget(
                            errorMessage: _detailsError!,
                            onRetry: () {
                              if (_stage == AcademyStage.sports) {
                                _fetchSports(_selectedAcademy!.id);
                              } else {
                                _fetchGroups(_selectedSport!.id);
                              }
                            },
                          )
                        : _stage == AcademyStage.sports
                            ? RefreshIndicator(
                                onRefresh: () => _fetchSports(_selectedAcademy!.id),
                                child: _sports.isEmpty
                                    ? ListView(
                                        children: const [
                                          SizedBox(height: 100),
                                          EmptyState(message: 'لا توجد رياضات في هذه الأكاديمية'),
                                        ],
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _sports.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == _sports.length) return const SizedBox(height: 100);
                                          final sport = _sports[index];
                                          return AppCard(
                                            onTap: () => _onSportTapped(sport),
                                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.2),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                                  radius: 20,
                                                  child: Text(
                                                    safeInitials(sport.nameAr),
                                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        sport.nameAr,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                      ),
                                                      Text(
                                                        sport.name,
                                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (user?.role == 'super_admin') ...[
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                    onPressed: () => _showAddEditSportDialog(sport),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                    onPressed: () => _showDeleteConfirmDialog(
                                                      title: 'تأكيد حذف الرياضة',
                                                      name: sport.nameAr,
                                                      onDelete: () async {
                                                        try {
                                                          await ref.read(departmentRepositoryProvider).deleteSport(sport.id);
                                                          _fetchSports(_selectedAcademy!.id);
                                                        } catch (e) {
                                                           if (context.mounted) {
                                                             ScaffoldMessenger.of(context).showSnackBar(
                                                               SnackBar(content: Text('خطأ: ${e.toString()}')),
                                                             );
                                                           }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                                const Icon(Icons.chevron_left, color: Colors.grey),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => _fetchGroups(_selectedSport!.id),
                                child: _groups.isEmpty
                                    ? ListView(
                                        children: const [
                                          SizedBox(height: 100),
                                          EmptyState(message: 'لا توجد مجموعات في هذه الرياضة'),
                                        ],
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _groups.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == _groups.length) return const SizedBox(height: 100);
                                          final group = _groups[index];
                                          return AppCard(
                                            onTap: user?.role == 'super_admin' ? () => _showAddEditGroupDialog(group) : null,
                                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.2),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(group.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                    if (user?.role == 'super_admin')
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                            onPressed: () => _showAddEditGroupDialog(group),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                            onPressed: () => _showDeleteConfirmDialog(
                                                              title: 'تأكيد حذف المجموعة',
                                                              name: group.nameAr,
                                                              onDelete: () async {
                                                                try {
                                                                  await ref.read(departmentRepositoryProvider).deleteGroup(group.id);
                                                                  _fetchGroups(_selectedSport!.id);
                                                                } catch (e) {
                                                                   if (context.mounted) {
                                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                                       SnackBar(content: Text('خطأ: ${e.toString()}')),
                                                                     );
                                                                   }
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('المدرب: ${group.coachName.isEmpty ? "بدون مدرب" : group.coachName}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                                const SizedBox(height: 4),
                                                Text('التوقيت: ${group.startTime} - ${group.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: group.days.map((d) {
                                                    final dayLabel = _weekDays.firstWhere((w) => w['value'] == d, orElse: () => {'label': d})['label'];
                                                    return Chip(
                                                      label: Text(dayLabel!, style: const TextStyle(fontSize: 10)),
                                                      visualDensity: VisualDensity.compact,
                                                      padding: EdgeInsets.zero,
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
          ),
        ],
      ),
    );
  }
}
