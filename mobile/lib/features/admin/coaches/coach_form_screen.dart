import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/admin_form_scaffold.dart';
import '../../../core/models/trainer_model.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/api_error_parser.dart';

class CoachFormScreen extends ConsumerStatefulWidget {
  final int? trainerId;

  const CoachFormScreen({super.key, this.trainerId});

  @override
  ConsumerState<CoachFormScreen> createState() => _CoachFormScreenState();
}

class _CoachFormScreenState extends ConsumerState<CoachFormScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isActive = true;
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isLoading = true;
  TrainerModel? _existingCoach;

  bool get _isEdit => widget.trainerId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_isEdit) {
      setState(() => _isLoading = false);
      return;
    }
    final trainers = ref.read(trainersProvider).valueOrNull ?? [];
    final coach = trainers.where((t) => t.id == widget.trainerId).firstOrNull;
    if (coach != null) {
      _existingCoach = coach;
      _firstNameController.text = coach.firstNameAr;
      _lastNameController.text = coach.lastNameAr;
      _phoneController.text = coach.phone;
      _isActive = coach.isActive;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
        setState(() => _selectedImage = File(picked.path));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final map = {
        'first_name_ar': _firstNameController.text.trim(),
        'last_name_ar': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().toWesternDigits(),
        'role': 'trainer',
        'is_active': _isActive,
      };
      if (_passwordController.text.isNotEmpty) {
        map['password'] = _passwordController.text;
      }
      final formData = FormData.fromMap(map);
      if (_selectedImage != null) {
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(_selectedImage!.path),
        ));
      }

      if (_isEdit) {
        await ref.read(trainerRepositoryProvider).updateTrainer(widget.trainerId!, formData);
      } else {
        await ref.read(trainerRepositoryProvider).createTrainer(formData);
      }
      ref.invalidate(trainersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تحديث المدرب بنجاح' : 'تم إضافة المدرب بنجاح')),
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
        appBar: AppBar(title: Text(_isEdit ? 'تعديل المدرب' : 'إضافة مدرب جديد')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AdminFormScaffold(
      title: _isEdit ? 'تعديل المدرب' : 'إضافة مدرب جديد',
      submitLabel: _isEdit ? 'حفظ التعديلات' : 'إضافة المدرب',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_existingCoach?.profileImage != null && _existingCoach!.profileImage!.isNotEmpty
                            ? NetworkImage(_existingCoach!.profileImage!) as ImageProvider
                            : null),
                    child: (_selectedImage == null && (_existingCoach?.profileImage == null || _existingCoach!.profileImage!.isEmpty))
                        ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
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
                    controller: _lastNameController,
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
                    controller: _firstNameController,
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
              controller: _phoneController,
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
              controller: _passwordController,
              obscureText: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: _isEdit ? 'كلمة المرور الجديدة (اختياري)' : 'كلمة المرور',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: _isEdit ? 'اتركه فارغاً للاحتفاظ بكلمة المرور القديمة' : 'مطلوب للمدرب الجديد',
              ),
              validator: (v) {
                if (!_isEdit && (v == null || v.trim().isEmpty)) {
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
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
              activeColor: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
