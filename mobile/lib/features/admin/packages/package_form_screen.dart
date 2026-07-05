import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/admin_form_scaffold.dart';
import '../../../core/models/package_model.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/api_error_parser.dart';

class PackageFormScreen extends ConsumerStatefulWidget {
  final int? packageId;

  const PackageFormScreen({super.key, this.packageId});

  @override
  ConsumerState<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends ConsumerState<PackageFormScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _valueController = TextEditingController(text: '1');
  final _athletesController = TextEditingController(text: '1');
  final _orderController = TextEditingController(text: '0');
  final _featuresController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _durationType = 'months';
  String _tag = 'normal';
  String _iconName = 'award';
  String _colorClass = 'blue';
  int? _selectedDeptId;
  bool _isActive = true;
  bool _isSubmitting = false;
  bool _isLoading = false;

  bool get _isEdit => widget.packageId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_isEdit) return;
    final packages = ref.read(packagesProvider).valueOrNull ?? [];
    final pkg = packages.where((p) => p.id == widget.packageId).firstOrNull;
    if (pkg != null) _populateForm(pkg);
    setState(() => _isLoading = false);
  }

  void _populateForm(PackageModel pkg) {
    _nameController.text = pkg.name;
    _descriptionController.text = pkg.description;
    _priceController.text = pkg.price.toString();
    _durationType = pkg.durationType;
    _valueController.text = pkg.durationValue.toString();
    _athletesController.text = pkg.maxAthletes.toString();
    _tag = pkg.tag;
    _iconName = pkg.iconName;
    _colorClass = pkg.colorClass;
    _orderController.text = pkg.order.toString();
    _isActive = pkg.isActive;
    _featuresController.text = pkg.features.join('\n');
    _selectedDeptId = pkg.department;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _valueController.dispose();
    _athletesController.dispose();
    _orderController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final features = _featuresController.text
          .split('\n')
          .map((l) => l.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim().toWesternDigits()),
        'duration_type': _durationType,
        'duration_value': int.parse(_valueController.text.trim().toWesternDigits()),
        'max_athletes': int.parse(_athletesController.text.trim().toWesternDigits()),
        'tag': _tag,
        'icon_name': _iconName.trim(),
        'color_class': _colorClass.trim(),
        'order': int.parse(_orderController.text.trim().toWesternDigits()),
        'is_active': _isActive,
        'features': features,
        'department': _selectedDeptId,
      };

      final repo = ref.read(packageRepositoryProvider);
      if (_isEdit) {
        await repo.updatePackage(widget.packageId!, data);
      } else {
        await repo.createPackage(data);
      }

      ref.invalidate(packagesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تعديل الباقة' : 'تمت إضافة الباقة')),
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
        appBar: AppBar(title: Text(_isEdit ? 'تعديل الباقة' : 'إضافة باقة جديدة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AdminFormScaffold(
      title: _isEdit ? 'تعديل الباقة' : 'إضافة باقة جديدة',
      submitLabel: _isEdit ? 'تعديل' : 'إضافة',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'اسم الباقة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              textAlign: TextAlign.right,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'الوصف',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'السعر (د.ل)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildDepartmentDropdown(isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _durationType,
                    decoration: InputDecoration(
                      labelText: 'نوع المدة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'months', child: Text('أشهر')),
                      DropdownMenuItem(value: 'weeks', child: Text('أسابيع')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _durationType = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'قيمة المدة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _athletesController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'أقصى عدد لاعبين',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tag,
              decoration: InputDecoration(
                labelText: 'علامة الباقة المميزة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('عادية')),
                DropdownMenuItem(value: 'discount', child: Text('خصم')),
                DropdownMenuItem(value: 'special', child: Text('خاصة')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _tag = val);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: _iconName),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'اسم الأيقونة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => _iconName = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: _colorClass),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'فئة اللون (كلاس)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => _colorClass = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orderController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'الترتيب',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _featuresController,
              textAlign: TextAlign.right,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'الميزات (كل ميزة في سطر منفصل)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('نشط ومتاح للجميع', textAlign: TextAlign.right),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
              activeColor: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown(bool isDark) {
    final departmentsAsync = ref.watch(departmentsProvider);
    return departmentsAsync.when(
      data: (list) => DropdownButtonFormField<int?>(
        value: _selectedDeptId,
        decoration: InputDecoration(
          labelText: 'القسم / الأكاديمية (اختياري)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dropdownColor: isDark ? AppColors.darkCard : Colors.white,
        items: [
          const DropdownMenuItem(value: null, child: Text('باقة عامة')),
          ...list.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nameAr))),
        ],
        onChanged: (v) => setState(() => _selectedDeptId = v),
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, s) => TextButton.icon(
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('فشل التحميل، اضغط لإعادة المحاولة', style: TextStyle(fontSize: 12)),
        onPressed: () => ref.invalidate(departmentsProvider),
      ),
    );
  }
}
