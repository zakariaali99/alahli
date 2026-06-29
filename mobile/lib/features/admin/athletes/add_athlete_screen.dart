import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/numeral_converter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/app_error_widget.dart';

class AddAthleteScreen extends ConsumerStatefulWidget {
  const AddAthleteScreen({super.key});

  @override
  ConsumerState<AddAthleteScreen> createState() => _AddAthleteScreenState();
}

class _AddAthleteScreenState extends ConsumerState<AddAthleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedGender = 'male';
  int? _selectedDepartmentId;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;
  String? _errorMessage;
  File? _selectedImage;
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _birthDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'LY'),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = NumberFormatter.formatDate(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      setState(() {
        _errorMessage = 'يرجى اختيار الأكاديمية/القسم المخصص للاعب';
      });
      return;
    }
    if (_selectedBirthDate == null) {
      setState(() {
        _errorMessage = 'يرجى إدخال تاريخ الميلاد';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(athleteRepositoryProvider);
      
      final formattedBirthDate = DateFormat('yyyy-MM-dd').format(_selectedBirthDate!);

      final Map<String, dynamic> data = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().toWesternDigits(),
        'parent_phone': _parentPhoneController.text.trim().toWesternDigits(),
        'birth_date': formattedBirthDate,
        'gender': _selectedGender,
        'department': _selectedDepartmentId,
        'notes': _notesController.text.trim(),
        'is_active': true,
      };

      if (_selectedImage != null) {
        data['photo'] = await MultipartFile.fromFile(_selectedImage!.path);
      }

      final formData = FormData.fromMap(data);

      await repo.createAthlete(formData);
      ref.invalidate(athletesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة اللاعب بنجاح')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scope manager
    if (user?.role == 'academy_manager' && _selectedDepartmentId == null) {
      _selectedDepartmentId = user?.academy;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة لاعب جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                AppErrorWidget(
                  errorMessage: _errorMessage!,
                  onRetry: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Avatar Picker
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                        child: _selectedImage == null
                            ? const Icon(Icons.add_a_photo, size: 40, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Full name
              TextFormField(
                controller: _nameController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل للاعب',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'يرجى إدخال اسم اللاعب';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف الخاص باللاعب',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'يرجى إدخال رقم الهاتف';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Parent Phone
              TextFormField(
                controller: _parentPhoneController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'رقم هاتف ولي الأمر (اختياري)',
                  prefixIcon: const Icon(Icons.supervised_user_circle_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Birth Date
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'تاريخ الميلاد',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onTap: () => _selectBirthDate(context),
              ),
              const SizedBox(height: 16),

              // Gender selection dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'الجنس',
                  prefixIcon: const Icon(Icons.face_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('ذكر')),
                  DropdownMenuItem(value: 'female', child: Text('أنثى')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedGender = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Department dropdown (Only if user is not academy_manager)
              if (user?.role != 'academy_manager') ...[
                deptsAsync.when(
                  data: (list) {
                    return DropdownButtonFormField<int?>(
                      value: _selectedDepartmentId,
                      decoration: InputDecoration(
                        labelText: 'الأكاديمية المخصصة للاعب',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                      items: list
                          .map((dept) => DropdownMenuItem<int?>(
                                value: dept.id,
                                child: Text(dept.nameAr),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDepartmentId = val;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (err, s) => Text('خطأ في تحميل الأكاديميات: $err'),
                ),
                const SizedBox(height: 16),
              ],

              // Notes field
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'ملاحظات إضافية حول اللاعب',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'إضافة اللاعب وحفظ البيانات',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
