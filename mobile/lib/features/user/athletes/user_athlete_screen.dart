import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_card.dart';

class UserAthleteScreen extends ConsumerStatefulWidget {
  const UserAthleteScreen({super.key});

  @override
  ConsumerState<UserAthleteScreen> createState() => _UserAthleteScreenState();
}

class _UserAthleteScreenState extends ConsumerState<UserAthleteScreen> {
  List<dynamic> _athletes = [];
  Map<String, dynamic>? _mySubscription;
  bool _loading = true;
  String? _error;

  // Add Athlete Form State
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  String? _photoBase64;
  XFile? _pickedFile;
  bool _submitting = false;
  String? _submitError;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = ref.read(authProvider);
    final isParent = user?.role == 'parent';

    try {
      final apiClient = ref.read(apiClientProvider);
      if (isParent) {
        final res = await apiClient.dio.get('/athletes/parent/athletes/');
        final data = res.data;
        if (data is Map && data['results'] != null) {
          _athletes = data['results'] as List;
        } else if (data is List) {
          _athletes = data;
        }
      } else {
        final res = await apiClient.dio.get('/subscriptions/');
        final data = res.data;
        List<dynamic> subs = [];
        if (data is Map && data['results'] != null) {
          subs = data['results'] as List;
        } else if (data is List) {
          subs = data;
        }
        if (subs.isNotEmpty) {
          _mySubscription = subs.first as Map<String, dynamic>;
        }
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل البيانات';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        final ext = image.name.split('.').last.toLowerCase();
        setState(() {
          _pickedFile = image;
          _photoBase64 = 'data:image/$ext;base64,$base64Str';
          _submitError = null;
        });
      }
    } catch (e) {
      setState(() {
        _submitError = 'حدث خطأ أثناء التقاط الصورة';
      });
    }
  }

  Future<void> _addAthlete() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoBase64 == null) {
      setState(() {
        _submitError = 'يرجى التقاط صورة شخصية للرياضي';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final birthDate = '${_yearController.text}-${_monthController.text.padLeft(2, '0')}-${_dayController.text.padLeft(2, '0')}';

      await apiClient.dio.post('/athletes/parent/athletes/', data: {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birth_date': birthDate,
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'height': double.tryParse(_heightController.text) ?? 0.0,
        'photo': _photoBase64,
      });

      setState(() {
        _showAddForm = false;
        _photoBase64 = null;
        _pickedFile = null;
        _nameController.clear();
        _phoneController.clear();
        _weightController.clear();
        _heightController.clear();
        _dayController.clear();
        _monthController.clear();
        _yearController.clear();
      });

      _fetchData();
    } catch (e) {
      setState(() {
        _submitError = 'فشل إضافة الرياضي. يرجى التأكد من البيانات.';
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isParent = user?.role == 'parent';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.destructive)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _fetchData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (isParent) {
      return Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الرياضيون المسجلون',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (!_showAddForm)
                    TextButton.icon(
                      onPressed: () => setState(() => _showAddForm = true),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة رياضي', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_showAddForm) ...[
                Form(
                  key: _formKey,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'إضافة رياضي جديد لرعايتك',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 16),

                        // Image Pick
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                              child: _pickedFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(
                                        File(_pickedFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt_outlined, size: 24, color: Color(0xFF0F4C81)),
                                        SizedBox(height: 4),
                                        Text('صورة اللاعب', style: TextStyle(fontSize: 10, color: Color(0xFF0F4C81))),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                          validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                          validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 12),

                        // Birth date fields
                        const Text('تاريخ الميلاد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedForeground)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dayController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(hintText: 'DD', contentPadding: EdgeInsets.zero),
                                validator: (val) => int.tryParse(val ?? '') == null ? 'خطأ' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _monthController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(hintText: 'MM', contentPadding: EdgeInsets.zero),
                                validator: (val) => int.tryParse(val ?? '') == null ? 'خطأ' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(hintText: 'YYYY', contentPadding: EdgeInsets.zero),
                                validator: (val) => int.tryParse(val ?? '') == null ? 'خطأ' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Weight Height
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'الوزن (كجم)'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'الطول (سم)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_submitError != null) ...[
                          Text(
                            _submitError!,
                            style: const TextStyle(color: AppColors.destructive, fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _showAddForm = false),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _submitting ? null : _addAthlete,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F4C81),
                              ),
                              child: _submitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('حفظ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_athletes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('لم تقم بإضافة أي رياضي بعد', style: TextStyle(color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _athletes.length,
                  itemBuilder: (context, index) {
                    final athlete = _athletes[index];
                    return AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.person, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  athlete['athlete_name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  athlete['athlete_membership'] ?? '',
                                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }

    // Single athlete user view
    final detail = user?.athleteDetail;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'بياناتي الرياضية',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: detail != null && detail.photo != null ? NetworkImage(detail.photo!) : null,
                    child: detail == null || detail.photo == null
                        ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    detail != null ? detail.fullName : (user?.fullNameAr ?? ''),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail != null ? detail.phone : (user?.phone ?? ''),
                    style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                  ),
                  if (detail != null && detail.membershipNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail.membershipNumber!,
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                  ],
                  if (detail != null && detail.departmentName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail.departmentName!,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],

                  if (_mySubscription != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkMuted : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _mySubscription!['package_name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('حالة الاشتراك:', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                              Text(
                                _mySubscription!['status'] == 'active'
                                    ? 'نشط'
                                    : _mySubscription!['status'] == 'pending'
                                        ? 'قيد الانتظار'
                                        : 'منتهي',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _mySubscription!['status'] == 'active'
                                      ? AppColors.secondary
                                      : _mySubscription!['status'] == 'pending'
                                          ? AppColors.warning
                                          : AppColors.destructive,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
