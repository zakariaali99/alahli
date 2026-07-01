import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/phone_validator.dart';
import '../../../core/helpers/photo_utils.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/helpers/numeral_converter.dart';

class AddAthleteScreen extends ConsumerStatefulWidget {
  const AddAthleteScreen({super.key});

  @override
  ConsumerState<AddAthleteScreen> createState() => _AddAthleteScreenState();
}

class _AddAthleteScreenState extends ConsumerState<AddAthleteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Scenario Selection: 'choose', 'athlete', 'parent', 'success'
  String _scenario = 'choose';

  // Forms Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _selectedGender = 'male';
  int? _selectedDepartmentId;
  DateTime? _selectedBirthDate;
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار صورة من الجهاز'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('إلغاء'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await PhotoUtils.pickFromCameraOrGallery(
        picker: picker,
        chooseSource: _chooseImageSource,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'تعذر الوصول للكاميرا. جرّب اختيار صورة من الجهاز.';
      });
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'LY'),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      setState(() {
        _errorMessage = 'يرجى اختيار تاريخ الميلاد';
      });
      return;
    }

    if (_scenario == 'athlete') {
      if (_selectedDepartmentId == null) {
        setState(() {
          _errorMessage = 'يرجى اختيار الأكاديمية المخصصة للاعب';
        });
        return;
      }
      if (_selectedImage == null) {
        setState(() {
          _errorMessage = 'يرجى التقاط أو رفع صورة شخصية للرياضي';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      final photoBase64 = await PhotoUtils.toBase64DataUri(_selectedImage);

      final Map<String, dynamic> payload = {
        'role': _scenario,
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().toWesternDigits(),
        'password': _passwordController.text,
        'birth_day': _selectedBirthDate!.day,
        'birth_month': _selectedBirthDate!.month,
        'birth_year': _selectedBirthDate!.year,
      };

      if (_scenario == 'athlete') {
        payload['gender'] = _selectedGender;
        payload['department'] = _selectedDepartmentId;
        payload['photo'] = photoBase64;
        
        final double? w = double.tryParse(_weightController.text.trim().toWesternDigits());
        final double? h = double.tryParse(_heightController.text.trim().toWesternDigits());
        if (w != null) payload['weight'] = w;
        if (h != null) payload['height'] = h;
      }

      // Hits register view endpoint: POST /auth/register/
      await apiClient.dio.post('/auth/register/', data: payload);

      ref.invalidate(registrationsProvider);

      setState(() {
        _scenario = 'success';
      });
    } catch (e) {
      String err = e.toString().replaceAll('Exception: ', '');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          err = data.values.map((v) => v.toString()).join('\n');
        } else {
          err = e.response?.data?.toString() ?? e.message ?? err;
        }
      }
      setState(() {
        _errorMessage = err;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة مستخدم جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_scenario == 'choose') {
      return _buildChooseScenario();
    }
    if (_scenario == 'success') {
      return _buildSuccessView();
    }
    return _buildFormView();
  }

  Widget _buildChooseScenario() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'أنشئ حساب رياضي أو ولي أمر مباشرة من لوحة الإدارة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Athlete Option Card
          InkWell(
            onTap: () {
              setState(() {
                _scenario = 'athlete';
                _errorMessage = null;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                color: isDark ? AppColors.darkCard : Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fitness_center, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تسجيل رياضي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'أنشئ حساب رياضي مع صورة وبيانات بدنية',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Parent Option Card
          InkWell(
            onTap: () {
              setState(() {
                _scenario = 'parent';
                _errorMessage = null;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.secondary.withValues(alpha: 0.3) : AppColors.secondary.withValues(alpha: 0.3),
                  width: 2,
                ),
                color: isDark ? AppColors.darkCard : Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people, size: 36, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تسجيل ولي أمر',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'أنشئ حساب ولي أمر لإدارة الرياضيين والاشتراكات',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: AppColors.secondary),
          const SizedBox(height: 24),
          const Text(
            'تم تسجيل الحساب بنجاح',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'تم إنشاء طلب التسجيل وحفظ البيانات بنجاح. يمكنك الآن مراجعة واعتماد الطلب من صفحة الطلبات الجديدة لتفعيل الحساب.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('العودة للقائمة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    final deptsAsync = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 120.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      _scenario = 'choose';
                      _errorMessage = null;
                    });
                  },
                ),
                Text(
                  _scenario == 'athlete' ? 'إنشاء حساب رياضي' : 'إنشاء حساب ولي أمر',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

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

            // Avatar Picker for Athlete
            if (_scenario == 'athlete') ...[
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
                        backgroundImage: _selectedImage != null ? FileImage(File(_selectedImage!.path)) : null,
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
              const SizedBox(height: 24),
            ],

            // Name
            TextFormField(
              controller: _nameController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل للرياضي',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'يرجى إدخال الاسم';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'يرجى إدخال رقم الهاتف';
                return PhoneValidator.validateLibyanPhone(val);
              },
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'يرجى إدخال كلمة المرور';
                if (val.length < 8) return 'كلمة المرور يجب أن لا تقل عن 8 خانات';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Birth Date
            InkWell(
              onTap: () => _selectBirthDate(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'تاريخ الميلاد',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _selectedBirthDate != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!).toWesternDigits()
                      : 'اختر تاريخ الميلاد',
                  style: TextStyle(
                    fontSize: 15,
                    color: _selectedBirthDate != null ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender & Department (Athlete Only)
            if (_scenario == 'athlete') ...[
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

              deptsAsync.when(
                data: (list) {
                  return DropdownButtonFormField<int?>(
                    value: _selectedDepartmentId,
                    decoration: InputDecoration(
                      labelText: 'الأكاديمية / القسم المخصص للاعب',
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

              // Weight / Height
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'الطول (سم)',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'مطلوب';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'الوزن (كجم)',
                        prefixIcon: const Icon(Icons.scale),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'مطلوب';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

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
                      'حفظ وإرسال طلب التسجيل',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
class DateFormat {
  final String formatPattern;
  DateFormat(this.formatPattern);

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String format(DateTime date) => formatDate(date);
}
