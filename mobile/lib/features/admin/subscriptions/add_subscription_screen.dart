import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/paginated_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/models/athlete_model.dart';
import '../../../core/models/package_model.dart';
import '../../../core/models/group_model.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  AthleteModel? _selectedAthlete;
  PackageModel? _selectedPackage;
  GroupModel? _selectedGroup;
  String _paymentMethod = 'cash';
  DateTime _startDate = DateTime.now();
  PlatformFile? _selectedInvoiceFile;

  bool _isSubmitting = false;

  Future<void> _pickInvoice() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedInvoiceFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في اختيار الملف: $e')),
        );
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAthlete == null || _selectedPackage == null || _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار اللاعب والباقة والمجموعة')),
      );
      return;
    }

    if (_paymentMethod == 'bank_transfer' && _selectedInvoiceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى رفع إيصال الدفع (PDF أو صورة) عند اختيار التحويل المصرفي')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final end = _selectedPackage!.durationType == 'weeks'
          ? _startDate.add(Duration(days: 7 * _selectedPackage!.durationValue))
          : DateTime(_startDate.year, _startDate.month + _selectedPackage!.durationValue, _startDate.day);

      final Map<String, dynamic> map = {
        'athlete': _selectedAthlete!.id,
        'package_name': _selectedPackage!.name,
        'group': _selectedGroup!.id,
        'amount': _selectedPackage!.price,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': end.toIso8601String().split('T')[0],
        'payment_method': _paymentMethod,
        'status': 'active', // Admin creates active by default
      };

      if (_paymentMethod == 'bank_transfer' && _selectedInvoiceFile != null) {
        if (_selectedInvoiceFile!.path != null) {
          map['invoice_pdf'] = await MultipartFile.fromFile(
            _selectedInvoiceFile!.path!,
            filename: _selectedInvoiceFile!.name,
          );
        } else if (_selectedInvoiceFile!.bytes != null) {
          map['invoice_pdf'] = MultipartFile.fromBytes(
            _selectedInvoiceFile!.bytes!,
            filename: _selectedInvoiceFile!.name,
          );
        }
      }

      if (!mounted) return;
      final formData = FormData.fromMap(map);

      await ref.read(subscriptionRepositoryProvider).createSubscription(formData);
      ref.invalidate(subscriptionsPaginatedProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الاشتراك بنجاح')),
        );
        if (context.mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final athletesAsync = ref.watch(athletesProvider(const {}));
    final packagesAsync = ref.watch(packagesProvider);
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة اشتراك جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: athletesAsync.when(
        data: (athletes) => packagesAsync.when(
          data: (packages) => groupsAsync.when(
            data: (groups) => SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 120.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'بيانات الاشتراك',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<AthleteModel>(
                      decoration: InputDecoration(
                        labelText: 'اللاعب',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                      items: athletes.map((a) => DropdownMenuItem(value: a, child: Text(a.fullName))).toList(),
                      onChanged: (val) => setState(() => _selectedAthlete = val),
                      validator: (v) => v == null ? 'الرجاء اختيار اللاعب' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<PackageModel>(
                      decoration: InputDecoration(
                        labelText: 'الباقة',
                        prefixIcon: const Icon(Icons.card_membership_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                      items: packages.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} - ${p.price.toString().toWesternDigits()} د.ل'))).toList(),
                      onChanged: (val) => setState(() => _selectedPackage = val),
                      validator: (v) => v == null ? 'الرجاء اختيار الباقة' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<GroupModel>(
                      decoration: InputDecoration(
                        labelText: 'المجموعة الرياضية',
                        prefixIcon: const Icon(Icons.group_work_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                      items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g.nameAr))).toList(),
                      onChanged: (val) => setState(() => _selectedGroup = val),
                      validator: (v) => v == null ? 'الرجاء اختيار المجموعة' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        labelText: 'طريقة الدفع',
                        prefixIcon: const Icon(Icons.payment_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل مصرفي')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _paymentMethod = val!;
                          if (_paymentMethod != 'bank_transfer') {
                            _selectedInvoiceFile = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // File Picker Section for Bank Transfer
                    if (_paymentMethod == 'bank_transfer') ...[
                      InkWell(
                        onTap: _pickInvoice,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedInvoiceFile != null ? AppColors.secondary : Colors.grey,
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedInvoiceFile != null ? Icons.check_circle : Icons.upload_file_outlined,
                                color: _selectedInvoiceFile != null ? AppColors.secondary : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedInvoiceFile != null
                                          ? _selectedInvoiceFile!.name
                                          : 'رفع إيصال التحويل المصرفي',
                                      style: TextStyle(
                                        fontWeight: _selectedInvoiceFile != null ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_selectedInvoiceFile != null)
                                      Text(
                                        'الحجم: ${(_selectedInvoiceFile!.size / 1024).toStringAsFixed(1)} KB',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              if (_selectedInvoiceFile != null)
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.destructive, size: 20),
                                  onPressed: () => setState(() => _selectedInvoiceFile = null),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ بداية الاشتراك',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _startDate.toIso8601String().split('T')[0].toWesternDigits(),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('إنشاء وتفعيل الاشتراك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('خطأ: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('خطأ: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}
