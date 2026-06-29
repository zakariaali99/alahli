import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/helpers/numeral_converter.dart';

final _packagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getPackages();
});

class PackageManagementScreen extends ConsumerStatefulWidget {
  const PackageManagementScreen({super.key});

  @override
  ConsumerState<PackageManagementScreen> createState() => _PackageManagementScreenState();
}

class _PackageManagementScreenState extends ConsumerState<PackageManagementScreen> {
  Future<void> _deletePackage(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الباقة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminRepositoryProvider).deletePackage(id);
      if (!mounted) return;
      ref.invalidate(_packagesProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الباقة'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red));
    }
  }

  void _showPackageDialog({Map<String, dynamic>? existing}) {
    final nameCtl = TextEditingController(text: existing?['name'] as String? ?? '');
    final descCtl = TextEditingController(text: existing?['description'] as String? ?? '');
    final priceCtl = TextEditingController(text: existing?['price']?.toString() ?? '');
    final durationValCtl = TextEditingController(text: (existing?['duration_value'] as int?)?.toString() ?? '1');
    final maxAthletesCtl = TextEditingController(text: (existing?['max_athletes'] as int?)?.toString() ?? '1');
    final featuresCtl = TextEditingController(text: (existing?['features'] as List?)?.join(', ') ?? '');
    
    String durationType = existing?['duration_type'] as String? ?? 'months';
    String tag = existing?['tag'] as String? ?? 'normal';
    bool isActive = existing?['is_active'] as bool? ?? true;
    
    final isEditing = existing != null;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'تعديل الباقة' : 'إضافة باقة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'اسم الباقة', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtl,
                  decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtl,
                  decoration: const InputDecoration(labelText: 'السعر (د.ل)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationValCtl,
                        decoration: const InputDecoration(labelText: 'قيمة المدة', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: durationType,
                        decoration: const InputDecoration(labelText: 'نوع المدة', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'weeks', child: Text('أسابيع')),
                          DropdownMenuItem(value: 'months', child: Text('أشهر')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => durationType = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxAthletesCtl,
                  decoration: const InputDecoration(labelText: 'أقصى عدد لاعبين', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tag,
                  decoration: const InputDecoration(labelText: 'النوع / التصنيف', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('عادية (Normal)')),
                    DropdownMenuItem(value: 'special', child: Text('مميزة (Special)')),
                    DropdownMenuItem(value: 'discount', child: Text('تخفيض (Discount)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => tag = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: featuresCtl,
                  decoration: const InputDecoration(labelText: 'المميزات (مفصولة بفواصل)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('نشط'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameCtl.text.trim().isEmpty) return;
                setDialogState(() => isSaving = true);
                try {
                  // Normalize numeric values
                  final cleanPriceStr = NumeralConverter.convert(priceCtl.text.trim());
                  final cleanDurationStr = NumeralConverter.convert(durationValCtl.text.trim());
                  final cleanMaxAthletesStr = NumeralConverter.convert(maxAthletesCtl.text.trim());

                  final data = {
                    'name': nameCtl.text.trim(),
                    'description': descCtl.text.trim(),
                    'price': cleanPriceStr,
                    'duration_type': durationType,
                    'duration_value': int.tryParse(cleanDurationStr) ?? 1,
                    'max_athletes': int.tryParse(cleanMaxAthletesStr) ?? 1,
                    'tag': tag,
                    'is_active': isActive,
                    'features': featuresCtl.text.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList(),
                  };
                  final repo = ref.read(adminRepositoryProvider);
                  if (isEditing) {
                    await repo.updatePackage(existing['id'] as int, data);
                  } else {
                    await repo.createPackage(data);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ref.invalidate(_packagesProvider);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red));
                  setDialogState(() => isSaving = false);
                }
              },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packagesAsync = ref.watch(_packagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('باقات الاشتراك'),
        actions: [
          TextButton.icon(
            onPressed: () => _showPackageDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_packagesProvider.future),
        child: packagesAsync.when(
          data: (packages) {
            if (packages.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.card_giftcard,
                message: 'لا توجد باقات',
                subtitle: 'أضف باقة اشتراك جديدة',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: packages.length,
              itemBuilder: (ctx, i) => _buildPackageCard(theme, packages[i]),
            );
          },
          loading: () => const ShimmerList(),
          error: (e, _) => AppErrorWidget(
            message: 'تعذر تحميل الباقات',
            onRetry: () => ref.invalidate(_packagesProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(ThemeData theme, Map<String, dynamic> pkg) {
    final id = pkg['id'] as int? ?? 0;
    final name = pkg['name'] as String? ?? '';
    final priceStr = pkg['price'] as String? ?? '0';
    final durationVal = pkg['duration_value'] as int? ?? 1;
    final durationType = pkg['duration_type'] as String? ?? 'months';
    final tag = pkg['tag'] as String? ?? 'normal';
    final maxAthletes = pkg['max_athletes'] as int? ?? 1;
    final features = pkg['features'] as List? ?? [];
    final isActive = pkg['is_active'] as bool? ?? true;

    final durationText = durationType == 'weeks' 
        ? '$durationVal أسبوع' 
        : '$durationVal شهر';

    Color tagColor = Colors.grey;
    String tagLabel = 'عادية';
    if (tag == 'special') {
      tagColor = Colors.orange;
      tagLabel = 'مميزة';
    } else if (tag == 'discount') {
      tagColor = Colors.red;
      tagLabel = 'تخفيض';
    }

    // Force standard numerals formatting for display
    final cleanPrice = NumeralConverter.convert(priceStr);
    final cleanMaxAthletes = NumeralConverter.convert(maxAthletes.toString());
    final cleanDurationText = NumeralConverter.convert(durationText);

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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.card_giftcard, color: tagColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(tagLabel, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$cleanPrice د.ل • $cleanDurationText • الحد الأقصى: $cleanMaxAthletes لاعبين', 
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _showPackageDialog(existing: pkg);
                  if (v == 'delete') _deletePackage(id);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.check, size: 14, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(NumeralConverter.convert(f.toString()), style: const TextStyle(fontSize: 12)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
