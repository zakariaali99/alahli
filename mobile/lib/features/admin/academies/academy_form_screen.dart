import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/admin_form_scaffold.dart';
import '../../../core/helpers/api_error_parser.dart';
import '../../../core/models/department_model.dart';

class AcademyFormScreen extends ConsumerStatefulWidget {
  final int? academyId;

  const AcademyFormScreen({super.key, this.academyId});

  @override
  ConsumerState<AcademyFormScreen> createState() => _AcademyFormScreenState();
}

class _AcademyFormScreenState extends ConsumerState<AcademyFormScreen> {
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _bankController = TextEditingController();
  final _ibanController = TextEditingController();
  final _colorController = TextEditingController(text: '#1570EF');
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _isLoading = false;

  bool get _isEdit => widget.academyId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_isEdit) return;
    final depts = ref.read(departmentsProvider).valueOrNull ?? [];
    final dept = depts.where((d) => d.id == widget.academyId).firstOrNull;
    if (dept != null) _populateForm(dept);
    setState(() => _isLoading = false);
  }

  void _populateForm(DepartmentModel dept) {
    _nameController.text = dept.name;
    _nameArController.text = dept.nameAr;
    _bankController.text = dept.bankAccountNumber;
    _ibanController.text = dept.iban;
    _colorController.text = dept.color;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _bankController.dispose();
    _ibanController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final formData = FormData.fromMap({
        'name': _nameController.text.trim(),
        'name_ar': _nameArController.text.trim(),
        'bank_account_number': _bankController.text.trim(),
        'iban': _ibanController.text.trim(),
        'color': _colorController.text.trim(),
      });

      final repo = ref.read(departmentRepositoryProvider);
      if (_isEdit) {
        await repo.updateDepartment(widget.academyId!, formData);
      } else {
        await repo.createDepartment(formData);
      }

      ref.invalidate(departmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تحديث الأكاديمية' : 'تم إضافة الأكاديمية بنجاح')),
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
        appBar: AppBar(title: Text(_isEdit ? 'تعديل الأكاديمية' : 'إضافة أكاديمية جديدة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AdminFormScaffold(
      title: _isEdit ? 'تعديل الأكاديمية' : 'إضافة أكاديمية جديدة',
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
            TextFormField(
              controller: _bankController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'رقم الحساب البنكي',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ibanController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'رقم الآيبان (IBAN)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _colorController,
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
    );
  }
}
