import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/phone_validator.dart';
import '../../../core/helpers/photo_utils.dart';
import '../../../core/helpers/api_error_parser.dart';
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
  final _residenceController = TextEditingController();
  final _healthStatusController = TextEditingController();

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
    _residenceController.dispose();
    _healthStatusController.dispose();

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
    try {
      final image = await PhotoUtils.pickFromCameraOrGallery(
        picker: _picker,
        chooseSource: _chooseImageSource,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (image != null) {
        final base64Data = await PhotoUtils.toBase64DataUri(image);
        setState(() {
          _pickedFile = image;
          _photoBase64 = base64Data;
          _submitError = null;
        });
      }
    } catch (e) {
      setState(() {
        _submitError = 'تعذر اختيار الصورة';
      });
    }
  }

  Future<void> _handleAddAthlete() async {
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
      await apiClient.dio.post('/athletes/parent/athletes/', data: {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'residence': _residenceController.text.trim(),
        'health_status': _healthStatusController.text.trim(),
        'birth_day': int.tryParse(_dayController.text),
        'birth_month': int.tryParse(_monthController.text),
        'birth_year': int.tryParse(_yearController.text),
        'photo': _photoBase64,
      });

      _nameController.clear();
      _phoneController.clear();
      _residenceController.clear();
      _healthStatusController.clear();
      _dayController.clear();
      _monthController.clear();
      _yearController.clear();
      _photoBase64 = null;
      _pickedFile = null;

      setState(() {
        _showAddForm = false;
      });

      await _fetchData();
    } catch (e) {
      final parsed = parseApiError(e);
      setState(() {
        _submitError = parsed.message;
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  void _showEditParentDialog() {
    final user = ref.read(authProvider);
    final nameCtrl = TextEditingController(text: user?.fullNameAr ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final whatsappCtrl = TextEditingController(text: user?.whatsappPhone ?? '');
    final residenceCtrl = TextEditingController(text: user?.residence ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بيانات ولي الأمر', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم بالكامل')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
              const SizedBox(height: 12),
              TextField(controller: whatsappCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الواتساب')),
              const SizedBox(height: 12),
              TextField(controller: residenceCtrl, decoration: const InputDecoration(labelText: 'السكن / العنوان')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              try {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.updateProfile(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  whatsappPhone: whatsappCtrl.text.trim(),
                  residence: residenceCtrl.text.trim(),
                );
                await ref.read(authProvider.notifier).reloadUser();
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح')));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('حفظ'),
          ),

        ],
      ),
    );
  }

  void _showEditChildDialog(int athleteId, String currentName, String? currentResidence, String? currentHealth) {
    final nameCtrl = TextEditingController(text: currentName);
    final residenceCtrl = TextEditingController(text: currentResidence ?? '');
    final healthCtrl = TextEditingController(text: currentHealth ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بيانات الطفل', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم بالكامل')),
              const SizedBox(height: 12),
              TextField(controller: residenceCtrl, decoration: const InputDecoration(labelText: 'السكن / العنوان')),
              const SizedBox(height: 12),
              TextField(controller: healthCtrl, decoration: const InputDecoration(labelText: 'الحالة الصحية')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              try {
                final repo = ref.read(athleteRepositoryProvider);
                await repo.updateAthleteJson(athleteId, {
                  'full_name': nameCtrl.text.trim(),
                  'residence': residenceCtrl.text.trim(),
                  'health_status': healthCtrl.text.trim(),
                });
                await _fetchData();
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات الرياضي')));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('حفظ'),
          ),

        ],
      ),
    );
  }

  void _showEditSelfDialog() {
    final user = ref.read(authProvider);
    final detail = user?.athleteDetail;
    final nameCtrl = TextEditingController(text: detail?.fullName ?? user?.fullNameAr ?? '');
    final phoneCtrl = TextEditingController(text: detail?.phone ?? user?.phone ?? '');
    final residenceCtrl = TextEditingController(text: detail?.residence ?? user?.residence ?? '');
    final healthCtrl = TextEditingController(text: detail?.healthStatus ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بياني الشخصي', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم بالكامل')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
              const SizedBox(height: 12),
              TextField(controller: residenceCtrl, decoration: const InputDecoration(labelText: 'السكن / العنوان')),
              const SizedBox(height: 12),
              TextField(controller: healthCtrl, decoration: const InputDecoration(labelText: 'الحالة الصحية')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              try {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.updateProfile(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  residence: residenceCtrl.text.trim(),
                );
                if (detail != null) {
                  final athleteRepo = ref.read(athleteRepositoryProvider);
                  await athleteRepo.updateAthleteJson(detail.id, {
                    'full_name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'residence': residenceCtrl.text.trim(),
                    'health_status': healthCtrl.text.trim(),
                  });
                }
                await ref.read(authProvider.notifier).reloadUser();
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بياناتك بنجاح')));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('حفظ'),
          ),

        ],
      ),
    );
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
              // Parent Info Card
              AppCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullNameAr ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('ولي أمر (أكاديمية الأوس)', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      onPressed: _showEditParentDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الأطفال / الرياضيون التابعون لك',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (!_showAddForm)
                    TextButton.icon(
                      onPressed: () => setState(() => _showAddForm = true),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة طفل', style: TextStyle(fontWeight: FontWeight.bold)),
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

                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.1),
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
                                        Icon(Icons.add_a_photo_outlined, size: 24, color: Color(0xFF0F4C81)),
                                        SizedBox(height: 4),
                                        Text('كاميرا / الجهاز', style: TextStyle(fontSize: 10, color: Color(0xFF0F4C81))),
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
                          validator: (val) => PhoneValidator.validateLibyanPhone(val) ?? (val == null || val.isEmpty ? 'مطلوب' : null),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _residenceController,
                          decoration: const InputDecoration(labelText: 'السكن / العنوان'),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _healthStatusController,
                          decoration: const InputDecoration(labelText: 'الحالة الصحية'),
                        ),
                        const SizedBox(height: 12),

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
                        const SizedBox(height: 16),

                        if (_submitError != null) ...[
                          Text(_submitError!, style: const TextStyle(color: AppColors.destructive, fontSize: 12)),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _submitting ? null : _handleAddAthlete,
                                child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('حفظ وإضافة'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => setState(() => _showAddForm = false),
                              child: const Text('إلغاء'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_athletes.isEmpty && !_showAddForm)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('لم تقم بإضافة أي طفل بعد', style: TextStyle(color: AppColors.mutedForeground)),
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
                    final athleteId = athlete['athlete'] as int? ?? 0;
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
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                            onPressed: () => _showEditChildDialog(
                              athleteId,
                              athlete['athlete_name'] ?? '',
                              athlete['residence'],
                              athlete['health_status'],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'بياناتي الرياضية (مركز الأهلي)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  onPressed: _showEditSelfDialog,
                ),
              ],
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
