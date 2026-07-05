import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/admin_form_scaffold.dart';
import '../../../core/helpers/api_error_parser.dart';
import '../../../core/models/group_model.dart';

class GroupFormScreen extends ConsumerStatefulWidget {
  final int sportId;
  final int? groupId;

  const GroupFormScreen({super.key, required this.sportId, this.groupId});

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _startTimeController = TextEditingController(text: '16:00');
  final _endTimeController = TextEditingController(text: '17:00');
  final _formKey = GlobalKey<FormState>();

  int? _selectedCoachId;
  List<String> _selectedDays = [];
  bool _isSubmitting = false;
  bool _isLoading = false;

  final List<Map<String, String>> _weekDays = [
    {'value': 'saturday', 'label': 'السبت'},
    {'value': 'sunday', 'label': 'الأحد'},
    {'value': 'monday', 'label': 'الإثنين'},
    {'value': 'tuesday', 'label': 'الثلاثاء'},
    {'value': 'wednesday', 'label': 'الأربعاء'},
    {'value': 'thursday', 'label': 'الخميس'},
    {'value': 'friday', 'label': 'الجمعة'},
  ];

  bool get _isEdit => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_isEdit) return;
    final groups = ref.read(groupsProvider).valueOrNull ?? [];
    final group = groups.where((g) => g.id == widget.groupId).firstOrNull;
    if (group != null) _populateForm(group);
    setState(() => _isLoading = false);
  }

  void _populateForm(GroupModel group) {
    _nameController.text = group.name;
    _nameArController.text = group.nameAr;
    _startTimeController.text = group.startTime;
    _endTimeController.text = group.endTime;
    _selectedCoachId = group.coachId;
    _selectedDays = List.from(group.days);
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار يوم واحد على الأقل')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'name_ar': _nameArController.text.trim(),
        'sport': widget.sportId,
        'coach': _selectedCoachId,
        'start_time': _startTimeController.text.trim(),
        'end_time': _endTimeController.text.trim(),
        'days': _selectedDays,
        'is_active': true,
      };

      final repo = ref.read(departmentRepositoryProvider);
      if (_isEdit) {
        await repo.updateGroup(widget.groupId!, data);
      } else {
        await repo.createGroup(data);
      }

      ref.invalidate(groupsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تحديث المجموعة' : 'تم إضافة المجموعة بنجاح')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final parsed = parseApiError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parsed.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AdminFormScaffold(
      title: _isEdit ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة',
      submitLabel: _isEdit ? 'حفظ' : 'إضافة',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameArController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'الاسم بالعربية',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'الاسم بالإنجليزية',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildCoachDropdown(isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
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
                    controller: _endTimeController,
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
                final isChecked = _selectedDays.contains(day['value']);
                return FilterChip(
                  label: Text(day['label']!),
                  selected: isChecked,
                  selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isChecked
                        ? AppColors.secondary
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedDays.add(day['value']!);
                      } else {
                        _selectedDays.remove(day['value']!);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachDropdown(bool isDark) {
    final trainersAsync = ref.watch(trainersProvider);
    return trainersAsync.when(
      data: (list) => DropdownButtonFormField<int?>(
        value: _selectedCoachId,
        decoration: InputDecoration(
          labelText: 'المدرب',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dropdownColor: isDark ? AppColors.darkCard : Colors.white,
        items: [
          const DropdownMenuItem(value: null, child: Text('بدون مدرب')),
          ...list.map((c) => DropdownMenuItem(value: c.id, child: Text(c.fullNameAr))),
        ],
        onChanged: (v) => setState(() => _selectedCoachId = v),
      ),
      loading: () => DropdownButtonFormField<int?>(
        value: null,
        decoration: InputDecoration(
          labelText: 'جاري تحميل المدربين...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (e, s) => TextButton.icon(
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('فشل التحميل، اضغط لإعادة المحاولة', style: TextStyle(fontSize: 12)),
        onPressed: () => ref.invalidate(trainersProvider),
      ),
    );
  }
}
