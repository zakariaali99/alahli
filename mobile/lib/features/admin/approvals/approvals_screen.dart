import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/helpers/numeral_converter.dart';

final _departmentsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDepartments();
});

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموافقات والطلبات'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'طلبات التسجيل الجديدة', icon: Icon(Icons.person_add_alt_1)),
            Tab(text: 'طلبات الاشتراكات المعلقة', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingRegistrationsTab(),
          _PendingSubscriptionsTab(),
        ],
      ),
    );
  }
}

class _PendingRegistrationsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PendingRegistrationsTab> createState() => _PendingRegistrationsTabState();
}

class _PendingRegistrationsTabState extends ConsumerState<_PendingRegistrationsTab> {
  void _showCreateProfileDialog(BuildContext context, Map<String, dynamic> reg) {
    final nameCtl = TextEditingController(text: reg['user']?['full_name_ar'] as String? ?? '');
    final phoneCtl = TextEditingController(text: reg['user']?['phone'] as String? ?? '');
    
    // 3-part birthdate variables
    String selectedDay = '1';
    String selectedMonth = '1';
    String selectedYear = '2010';
    
    String gender = 'male';
    int? selectedDeptId;
    final weightCtl = TextEditingController();
    final heightCtl = TextEditingController();
    
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final deptsAsync = ref.watch(_departmentsListProvider);

          return AlertDialog(
            title: const Text('إنشاء ملف لاعب جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل (عربي)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtl,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    enabled: false, // Phone is pre-filled and locked from registration request
                  ),
                  const SizedBox(height: 12),
                  
                  // 3-part birthdate layout
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('تاريخ الميلاد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  Row(
                    children: [
                      // Year selection
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: const InputDecoration(labelText: 'السنة', contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                          items: List.generate(40, (index) => (DateTime.now().year - index).toString())
                              .map((y) => DropdownMenuItem(value: y, child: Text(NumeralConverter.convert(y))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setDialogState(() => selectedYear = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Month selection
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMonth,
                          decoration: const InputDecoration(labelText: 'الشهر', contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                          items: List.generate(12, (index) => (index + 1).toString())
                              .map((m) => DropdownMenuItem(value: m, child: Text(NumeralConverter.convert(m))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setDialogState(() => selectedMonth = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Day selection
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedDay,
                          decoration: const InputDecoration(labelText: 'اليوم', contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                          items: List.generate(31, (index) => (index + 1).toString())
                              .map((d) => DropdownMenuItem(value: d, child: Text(NumeralConverter.convert(d))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setDialogState(() => selectedDay = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(labelText: 'الجنس', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('ذكر')),
                      DropdownMenuItem(value: 'female', child: Text('أنثى')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => gender = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  deptsAsync.when(
                    data: (depts) => DropdownButtonFormField<int>(
                      value: selectedDeptId,
                      decoration: const InputDecoration(labelText: 'الأكاديمية / القسم', border: OutlineInputBorder()),
                      items: depts.map((d) => DropdownMenuItem(value: d['id'] as int, child: Text(d['name_ar'] as String? ?? d['name'] as String? ?? ''))).toList(),
                      onChanged: (v) => setDialogState(() => selectedDeptId = v),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('خطأ في تحميل الأكاديميات: $e'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightCtl,
                          decoration: const InputDecoration(labelText: 'الوزن (كجم)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: heightCtl,
                          decoration: const InputDecoration(labelText: 'الطول (سم)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (nameCtl.text.isEmpty || selectedDeptId == null) return;
                  setDialogState(() => isSaving = true);
                  try {
                    // Enforce standard numerals
                    final day = NumeralConverter.convert(selectedDay);
                    final month = NumeralConverter.convert(selectedMonth);
                    final year = NumeralConverter.convert(selectedYear);
                    final dateOfBirthStr = '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
                    
                    final cleanWeight = NumeralConverter.convert(weightCtl.text.trim());
                    final cleanHeight = NumeralConverter.convert(heightCtl.text.trim());

                    final data = {
                      'full_name': nameCtl.text.trim(),
                      'phone': phoneCtl.text.trim(),
                      'birth_date': dateOfBirthStr,
                      'gender': gender,
                      'department_id': selectedDeptId,
                      if (cleanWeight.isNotEmpty) 'weight': double.tryParse(cleanWeight),
                      if (cleanHeight.isNotEmpty) 'height': double.tryParse(cleanHeight),
                    };

                    await ref.read(adminRepositoryProvider).createAthleteProfileForRegistration(reg['id'] as int, data);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ref.invalidate(pendingRegistrationsProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء ملف اللاعب بنجاح! يمكن الآن إتمام الموافقة.'), backgroundColor: Colors.green));
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red));
                    setDialogState(() => isSaving = false);
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('إنشاء الملف'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processRegistration(int id, bool approve) async {
    try {
      if (approve) {
        await ref.read(adminRepositoryProvider).approveRegistrationRequest(id);
      } else {
        await ref.read(adminRepositoryProvider).rejectRegistrationRequest(id);
      }
      ref.invalidate(pendingRegistrationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'تم قبول طلب التسجيل بنجاح' : 'تم رفض طلب التسجيل'),
          backgroundColor: approve ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل المعالجة: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registrationsAsync = ref.watch(pendingRegistrationsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(pendingRegistrationsProvider.future),
      child: registrationsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.person_add_disabled,
              message: 'لا توجد طلبات تسجيل معلقة',
              subtitle: 'كل طلبات تسجيل المشتركين الجدد تم معالجتها.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (ctx, i) {
              final reg = requests[i];
              final id = reg['id'] as int;
              final user = reg['user'] as Map<String, dynamic>? ?? {};
              final name = user['full_name_ar'] as String? ?? '';
              final phone = user['phone'] as String? ?? '';
              final hasProfile = reg['athlete'] != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasProfile ? Colors.blue.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasProfile ? 'تم إنشاء الملف' : 'ينتظر إنشاء الملف',
                            style: TextStyle(color: hasProfile ? Colors.blue : Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('رقم الهاتف: ${NumeralConverter.convert(phone)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!hasProfile)
                          ElevatedButton.icon(
                            onPressed: () => _showCreateProfileDialog(context, reg),
                            icon: const Icon(Icons.folder_shared_outlined, size: 16),
                            label: const Text('إنشاء ملف لاعب'),
                            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer, foregroundColor: theme.colorScheme.onPrimaryContainer),
                          )
                        else ...[
                          OutlinedButton(
                            onPressed: () => _processRegistration(id, false),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            child: const Text('رفض'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _processRegistration(id, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text('موافقة وقبول'),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: 'تعذر تحميل طلبات التسجيل',
          onRetry: () => ref.invalidate(pendingRegistrationsProvider),
        ),
      ),
    );
  }
}

class _PendingSubscriptionsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PendingSubscriptionsTab> createState() => _PendingSubscriptionsTabState();
}

class _PendingSubscriptionsTabState extends ConsumerState<_PendingSubscriptionsTab> {
  Future<void> _processSubscription(int id, bool approve) async {
    try {
      final status = approve ? 'active' : 'rejected';
      await ref.read(adminRepositoryProvider).updateSubscription(id, {'status': status});
      ref.invalidate(pendingSubscriptionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'تمت الموافقة وتفعيل الاشتراك' : 'تم رفض وإلغاء طلب الاشتراك'),
          backgroundColor: approve ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل المعالجة: $e'), backgroundColor: Colors.red));
    }
  }

  void _showReceiptDialog(BuildContext context, String receiptUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إيصال التحويل البنكي'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              receiptUrl,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                    SizedBox(height: 12),
                    Text('إيصال PDF أو مستند تحويل.', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('يمكن تنزيله أو عرضه في المتصفح.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionsAsync = ref.watch(pendingSubscriptionsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(pendingSubscriptionsProvider.future),
      child: subscriptionsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.payments_outlined,
              message: 'لا توجد طلبات اشتراكات معلقة',
              subtitle: 'كل المدفوعات والاشتراكات الجارية تم تفعيلها بالكامل.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subs.length,
            itemBuilder: (ctx, i) {
              final sub = subs[i];
              final id = sub['id'] as int;
              final athlete = sub['athlete'] as Map<String, dynamic>? ?? {};
              final athleteName = athlete['full_name'] as String? ?? '';
              final memberNum = athlete['membership_number'] as String? ?? '';
              
              final packageName = sub['package_name'] as String? ?? '';
              final amount = sub['amount']?.toString() ?? '0';
              final method = sub['payment_method'] as String? ?? 'cash';
              final receiptUrl = sub['invoice_pdf'] as String?;

              final cleanAmount = NumeralConverter.convert(amount);
              final cleanMemberNum = NumeralConverter.convert(memberNum);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(athleteName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: method == 'bank_transfer' ? Colors.purple.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            method == 'bank_transfer' ? 'تحويل بنكي' : 'نقداً (كاش)',
                            style: TextStyle(color: method == 'bank_transfer' ? Colors.purple : Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('رقم العضوية: $cleanMemberNum', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text('الباقة المطلوبة: $packageName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('القيمة المستحقة: $cleanAmount د.ل', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (method == 'bank_transfer' && receiptUrl != null && receiptUrl.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _showReceiptDialog(context, receiptUrl),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('عرض الإيصال'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(color: theme.colorScheme.primary),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => _processSubscription(id, false),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                              child: const Text('رفض'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _processSubscription(id, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('موافقة'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: 'تعذر تحميل طلبات الاشتراكات',
          onRetry: () => ref.invalidate(pendingSubscriptionsProvider),
        ),
      ),
    );
  }
}
