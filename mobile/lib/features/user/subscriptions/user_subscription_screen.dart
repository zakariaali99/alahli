import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_card.dart';

class UserSubscriptionScreen extends ConsumerStatefulWidget {
  const UserSubscriptionScreen({super.key});

  @override
  ConsumerState<UserSubscriptionScreen> createState() => _UserSubscriptionScreenState();
}

class _UserSubscriptionScreenState extends ConsumerState<UserSubscriptionScreen> {
  int _step = 0;
  
  // Data collected during steps
  int? _selectedAthleteId;
  // ignore: unused_field
  String? _selectedAthleteName;
  
  // ignore: unused_field
  Map<String, dynamic>? _selectedAcademy;
  Map<String, dynamic>? _selectedSport;
  Map<String, dynamic>? _selectedGroup;
  Map<String, dynamic>? _selectedPackage;
  
  String? _paymentMethod; // 'cash' or 'bank_transfer'
  XFile? _receiptImage;

  // Loading and Error states
  bool _loading = false;
  String? _error;
  bool _success = false;

  // Bank Info state
  Map<String, dynamic>? _bankInfo;
  bool _bankLoading = false;

  // Options fetched from API
  List<dynamic> _athletes = [];
  List<dynamic> _academies = [];
  List<dynamic> _sports = [];
  List<dynamic> _groups = [];
  List<dynamic> _packages = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initWorkflow());
  }

  Future<void> _initWorkflow() async {
    final user = ref.read(authProvider);
    final isParent = user?.role == 'parent';

    if (isParent) {
      await _fetchAthletes();
    } else {
      _selectedAthleteId = user?.athleteDetail?.id ?? user?.id;
      _selectedAthleteName = user?.fullNameAr;
      await _fetchAcademies();
    }
  }

  Future<void> _fetchAthletes() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/athletes/parent/athletes/');
      final data = res.data;
      setState(() {
        if (data is Map && data['results'] != null) {
          _athletes = data['results'] as List;
        } else if (data is List) {
          _athletes = data;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'فشل تحميل الرياضيين'; });
    }
  }

  Future<void> _fetchAcademies() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/departments/');
      final data = res.data;
      setState(() {
        if (data is Map && data['results'] != null) {
          _academies = data['results'] as List;
        } else if (data is List) {
          _academies = data;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'فشل تحميل الأكاديميات'; });
    }
  }

  Future<void> _fetchSports(int deptId) async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/sports/?department=$deptId');
      final data = res.data;
      setState(() {
        if (data is Map && data['results'] != null) {
          _sports = data['results'] as List;
        } else if (data is List) {
          _sports = data;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'فشل تحميل الرياضات'; });
    }
  }

  Future<void> _fetchGroups(int sportId) async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/groups/?sport=$sportId');
      final data = res.data;
      setState(() {
        if (data is Map && data['results'] != null) {
          _groups = data['results'] as List;
        } else if (data is List) {
          _groups = data;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'فشل تحميل المجموعات'; });
    }
  }

  Future<void> _fetchPackages() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/packages/');
      final data = res.data;
      setState(() {
        if (data is Map && data['results'] != null) {
          _packages = data['results'] as List;
        } else if (data is List) {
          _packages = data;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'فشل تحميل الباقات'; });
    }
  }

  Future<void> _fetchBankDetails(int groupId) async {
    setState(() { _bankLoading = true; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/subscriptions/bank_details/?group_id=$groupId');
      setState(() {
        _bankInfo = res.data as Map<String, dynamic>;
        _bankLoading = false;
      });
    } catch (e) {
      setState(() {
        _bankInfo = null;
        _bankLoading = false;
      });
    }
  }

  Future<void> _pickReceipt() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _receiptImage = image;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء تحديد الملف';
      });
    }
  }

  Future<void> _checkout() async {
    if (_paymentMethod == 'bank_transfer' && _receiptImage == null) {
      setState(() { _error = 'يرجى إرفاق إيصال التحويل المصرفي'; });
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);

      final Map<String, dynamic> dataMap = {
        'sport_id': _selectedSport!['id'],
        'group_id': _selectedGroup!['id'],
        'package_id': _selectedPackage!['id'],
        'payment_method': _paymentMethod,
      };

      if (_selectedAthleteId != null) {
        dataMap['athlete_id'] = _selectedAthleteId;
      }

      if (_receiptImage != null) {
        dataMap['invoice_pdf'] = await MultipartFile.fromFile(
          _receiptImage!.path,
          filename: 'receipt.pdf',
        );
      }

      final formData = FormData.fromMap(dataMap);

      await apiClient.dio.post('/subscriptions/checkout/', data: formData);
      setState(() {
        _success = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'فشل تأكيد الاشتراك. يرجى المحاولة مرة أخرى.';
      });
    }
  }

  void _nextStep() {
    setState(() {
      _step++;
    });
  }

  void _prevStep() {
    setState(() {
      _step--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isParent = user?.role == 'parent';
    final totalSteps = isParent ? 6 : 5;
    final theme = Theme.of(context);

    if (_success) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 80),
                const SizedBox(height: 24),
                Text(
                  'تم إرسال طلب الاشتراك بنجاح',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تم إرسال طلب اشتراكك وهو الآن قيد المراجعة والاعتماد من قبل الإدارة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedForeground, height: 1.5),
                ),
                if (_paymentMethod == 'bank_transfer' && _bankInfo != null) ...[
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('حساب الأكاديمية المصرفي:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('رقم الحساب: ${_bankInfo!['account_number'] ?? ''}', style: const TextStyle(fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Text('IBAN: ${_bankInfo!['iban'] ?? ''}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _success = false;
                        _step = 0;
                        _receiptImage = null;
                        _paymentMethod = null;
                        _selectedAcademy = null;
                        _selectedSport = null;
                        _selectedGroup = null;
                        _selectedPackage = null;
                        _initWorkflow();
                      });
                    },
                    child: const Text('اشتراك آخر'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: List.generate(totalSteps, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _step ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildStepContent(isParent),
                ),
              ),

            if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_error!, style: const TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold)),
              ),
            ],

            // Step Navigation Buttons
            if (!_loading && _step > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('السابق'),
                    ),
                    const Spacer(),
                    if (_step == totalSteps - 1)
                      FilledButton(
                        onPressed: _checkout,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('تأكيد الاشتراك'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isParent) {
    final theme = Theme.of(context);
    
    // Parent step 0: Select Athlete
    if (isParent && _step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('اختر الرياضي البطل', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_athletes.isEmpty)
            const Text('يرجى إضافة لاعب أولاً في صفحة "الرياضيون".', style: TextStyle(color: AppColors.mutedForeground))
          else
            ..._athletes.map((a) {
              return AppCard(
                onTap: () {
                  setState(() {
                    _selectedAthleteId = a['athlete'];
                    _selectedAthleteName = a['athlete_name'];
                  });
                  _fetchAcademies();
                  _nextStep();
                },
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['athlete_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(a['athlete_membership'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_back_ios, size: 16),
                  ],
                ),
              );
            }),
        ],
      );
    }

    // Step: Select Academy
    if ((isParent && _step == 1) || (!isParent && _step == 0)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('اختر الأكاديمية', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._academies.map((a) {
            final colorHex = a['color'] as String? ?? '#00288E';
            final color = Color(int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16));
            return AppCard(
              onTap: () {
                setState(() { _selectedAcademy = a; });
                _fetchSports(a['id']);
                _nextStep();
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text((a['name_ar'] ?? '').substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['name_ar'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(a['name'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_back_ios, size: 16),
                ],
              ),
            );
          }),
        ],
      );
    }

    // Step: Select Sport
    if ((isParent && _step == 2) || (!isParent && _step == 1)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('اختر الرياضة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._sports.map((s) {
            return AppCard(
              onTap: () {
                setState(() { _selectedSport = s; });
                _fetchGroups(s['id']);
                _nextStep();
              },
              child: Row(
                children: [
                  Text(s['name_ar'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Icon(Icons.arrow_back_ios, size: 16),
                ],
              ),
            );
          }),
        ],
      );
    }

    // Step: Select Group
    if ((isParent && _step == 3) || (!isParent && _step == 2)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('اختر المجموعة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._groups.map((g) {
            return AppCard(
              onTap: () {
                setState(() { _selectedGroup = g; });
                _fetchPackages();
                _nextStep();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g['name_ar'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('المدرب: ${g['coach_name'] ?? ''}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('الوقت: ${g['start_time'] ?? ''} - ${g['end_time'] ?? ''}', style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }),
        ],
      );
    }

    // Step: Select Package
    if ((isParent && _step == 4) || (!isParent && _step == 3)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('اختر الباقة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._packages.map((p) {
            return AppCard(
              onTap: () {
                setState(() { _selectedPackage = p; });
                _nextStep();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('${p['price'] ?? 0} د.ل', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('المدة: ${p['duration_value'] ?? ''} ${p['duration_type'] == 'months' ? 'شهر' : 'أسبوع'}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      );
    }

    // Step: Payment Method
    if ((isParent && _step == 5) || (!isParent && _step == 4)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('طريقة الدفع', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppCard(
            color: _paymentMethod == 'cash' ? AppColors.primaryContainer.withValues(alpha: 0.1) : null,
            border: _paymentMethod == 'cash' ? Border.all(color: AppColors.primary) : null,
            onTap: () {
              setState(() { _paymentMethod = 'cash'; });
            },
            child: const Row(
              children: [
                Icon(Icons.money, color: AppColors.primary),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نقداً', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('الدفع في مقر النادي', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            color: _paymentMethod == 'bank_transfer' ? AppColors.primaryContainer.withValues(alpha: 0.1) : null,
            border: _paymentMethod == 'bank_transfer' ? Border.all(color: AppColors.primary) : null,
            onTap: () {
              setState(() { _paymentMethod = 'bank_transfer'; });
              _fetchBankDetails(_selectedGroup!['id']);
            },
            child: const Row(
              children: [
                Icon(Icons.account_balance, color: AppColors.primary),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تحويل بنكي', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('إرفاق إيصال الدفع المصرفي', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),

          if (_paymentMethod == 'bank_transfer') ...[
            const SizedBox(height: 24),
            if (_bankLoading)
              const Center(child: CircularProgressIndicator())
            else if (_bankInfo != null)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('بيانات حساب الأكاديمية المصرفي:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('رقم الحساب: ${_bankInfo!['account_number'] ?? ''}', style: const TextStyle(fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    Text('IBAN: ${_bankInfo!['iban'] ?? ''}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickReceipt,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, style: BorderStyle.none),
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      _receiptImage != null ? _receiptImage!.name : 'اضغط لالتقاط أو اختيار صورة الإيصال',
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
