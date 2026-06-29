import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  bool _isSubmitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAthlete == null || _selectedPackage == null || _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار اللاعب والباقة والمجموعة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final end = _selectedPackage!.durationType == 'weeks'
          ? _startDate.add(Duration(days: 7 * _selectedPackage!.durationValue))
          : DateTime(_startDate.year, _startDate.month + _selectedPackage!.durationValue, _startDate.day);

      final data = {
        'athlete': _selectedAthlete!.id,
        'package_name': _selectedPackage!.name,
        'group': _selectedGroup!.id,
        'amount': _selectedPackage!.price,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': end.toIso8601String().split('T')[0],
        'payment_method': _paymentMethod,
        'status': 'active', // Admin creates active by default
      };

      await ref.read(subscriptionRepositoryProvider).createSubscription(data);
      ref.invalidate(subscriptionsPaginatedProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الاشتراك بنجاح')),
        );
        context.pop();
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
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('بيانات الاشتراك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<AthleteModel>(
                      decoration: const InputDecoration(labelText: 'اللاعب'),
                      items: athletes.map((a) => DropdownMenuItem(value: a, child: Text(a.fullName))).toList(),
                      onChanged: (val) => setState(() => _selectedAthlete = val),
                      validator: (v) => v == null ? 'الرجاء اختيار اللاعب' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<PackageModel>(
                      decoration: const InputDecoration(labelText: 'الباقة'),
                      items: packages.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} - ${p.price.toString().toWesternDigits()} د.ل'))).toList(),
                      onChanged: (val) => setState(() => _selectedPackage = val),
                      validator: (v) => v == null ? 'الرجاء اختيار الباقة' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<GroupModel>(
                      decoration: const InputDecoration(labelText: 'المجموعة الرياضية'),
                      items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g.nameAr))).toList(),
                      onChanged: (val) => setState(() => _selectedGroup = val),
                      validator: (v) => v == null ? 'الرجاء اختيار المجموعة' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل مصرفي')),
                      ],
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      title: const Text('تاريخ بداية الاشتراك'),
                      subtitle: Text(_startDate.toIso8601String().split('T')[0].toWesternDigits()),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
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
