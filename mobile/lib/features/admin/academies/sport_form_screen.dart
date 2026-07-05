import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/admin_form_scaffold.dart';
import '../../../core/helpers/api_error_parser.dart';
import '../../../core/models/sport_model.dart';

class SportFormScreen extends ConsumerStatefulWidget {
  final int academyId;
  final int? sportId;

  const SportFormScreen({super.key, required this.academyId, this.sportId});

  @override
  ConsumerState<SportFormScreen> createState() => _SportFormScreenState();
}

class _SportFormScreenState extends ConsumerState<SportFormScreen> {
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _isLoading = false;

  bool get _isEdit => widget.sportId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_isEdit) return;
    final sports = ref.read(sportsProvider).valueOrNull ?? [];
    final sport = sports.where((s) => s.id == widget.sportId).firstOrNull;
    if (sport != null) _populateForm(sport);
    setState(() => _isLoading = false);
  }

  void _populateForm(SportModel sport) {
    _nameController.text = sport.name;
    _nameArController.text = sport.nameAr;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'name_ar': _nameArController.text.trim(),
        'department': widget.academyId,
        'is_active': true,
      };

      final repo = ref.read(departmentRepositoryProvider);
      if (_isEdit) {
        await repo.updateSport(widget.sportId!, data);
      } else {
        await repo.createSport(data);
      }

      ref.invalidate(sportsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تحديث الرياضة' : 'تم إضافة الرياضة بنجاح')),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'تعديل الرياضة' : 'إضافة رياضة جديدة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AdminFormScaffold(
      title: _isEdit ? 'تعديل الرياضة' : 'إضافة رياضة جديدة',
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
          ],
        ),
      ),
    );
  }
}
