import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/models/package_model.dart';
import '../../../core/models/department_model.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  void _showAddEditPackageDialog([PackageModel? package]) async {
    final nameController = TextEditingController(text: package?.name ?? '');
    final descriptionController = TextEditingController(text: package?.description ?? '');
    final priceController = TextEditingController(text: package?.price.toString() ?? '');
    final typeController = TextEditingController(text: package?.durationType ?? 'months');
    final valueController = TextEditingController(text: package?.durationValue.toString() ?? '1');
    final athletesController = TextEditingController(text: package?.maxAthletes.toString() ?? '1');
    final tagController = TextEditingController(text: package?.tag ?? 'normal');
    final iconNameController = TextEditingController(text: package?.iconName ?? 'award');
    final colorClassController = TextEditingController(text: package?.colorClass ?? 'blue');
    final orderController = TextEditingController(text: package?.order.toString() ?? '0');
    final featuresController = TextEditingController(text: package?.features.join('\n') ?? '');
    
    int? selectedDeptId = package?.department;
    bool isActive = package?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final departmentsAsync = ref.watch(departmentsProvider);
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      package == null ? 'إضافة باقة جديدة' : 'تعديل الباقة',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: nameController,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'اسم الباقة',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: descriptionController,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'الوصف',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'السعر (د.ل)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 12),
                            departmentsAsync.when(
                              data: (list) {
                                return DropdownButtonFormField<int?>(
                                  value: selectedDeptId,
                                  decoration: InputDecoration(
                                    labelText: 'القسم / الأكاديمية (اختياري)',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('باقة عامة')),
                                    ...list.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nameAr))),
                                  ],
                                  onChanged: (v) => setDlgState(() => selectedDeptId = v),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (e, s) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: typeController.text,
                                    decoration: InputDecoration(
                                      labelText: 'نوع المدة',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                                    items: const [
                                      DropdownMenuItem(value: 'months', child: Text('أشهر')),
                                      DropdownMenuItem(value: 'weeks', child: Text('أسابيع')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDlgState(() => typeController.text = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: valueController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      labelText: 'قيمة المدة',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: athletesController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'أقصى عدد لاعبين',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: tagController.text,
                              decoration: InputDecoration(
                                labelText: 'علامة الباقة المميزة',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                              items: const [
                                DropdownMenuItem(value: 'normal', child: Text('عادية')),
                                DropdownMenuItem(value: 'discount', child: Text('خصم')),
                                DropdownMenuItem(value: 'special', child: Text('خاصة')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDlgState(() => tagController.text = val);
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: iconNameController,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      labelText: 'اسم الأيقونة',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: colorClassController,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      labelText: 'فئة اللون (كلاس)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: orderController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'الترتيب',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: featuresController,
                              textAlign: TextAlign.right,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'الميزات (كل ميزة في سطر منفصل)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('نشط ومتاح للجميع', textAlign: TextAlign.right),
                              value: isActive,
                              onChanged: (val) => setDlgState(() => isActive = val),
                              activeColor: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(ctx, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(package == null ? 'إضافة' : 'تعديل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirm == true) {
      try {
        final parsedFeatures = featuresController.text
            .split('\n')
            .map((line) => line.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final data = {
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
          'price': double.parse(priceController.text.trim().toWesternDigits()),
          'duration_type': typeController.text,
          'duration_value': int.parse(valueController.text.trim().toWesternDigits()),
          'max_athletes': int.parse(athletesController.text.trim().toWesternDigits()),
          'tag': tagController.text,
          'icon_name': iconNameController.text.trim(),
          'color_class': colorClassController.text.trim(),
          'order': int.parse(orderController.text.trim().toWesternDigits()),
          'is_active': isActive,
          'features': parsedFeatures,
          'department': selectedDeptId,
        };

        if (package == null) {
          await ref.read(packageRepositoryProvider).createPackage(data);
        } else {
          await ref.read(packageRepositoryProvider).updatePackage(package.id, data);
        }
        
        ref.invalidate(packagesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(package == null ? 'تمت إضافة الباقة' : 'تم تعديل الباقة')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _confirmDelete(PackageModel package) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: Text('هل أنت متأكد من حذف الباقة "${package.name}"؟\nقد يؤثر ذلك على الاشتراكات المرتبطة بها.', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(packageRepositoryProvider).deletePackage(package.id);
        ref.invalidate(packagesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الباقة بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(packagesProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPackageDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Text(
              'إدارة الباقات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(packagesProvider);
                ref.invalidate(departmentsProvider);
              },
              child: packagesAsync.when(
                data: (packages) {
                  if (packages.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('لا توجد باقات متاحة')),
                      ],
                    );
                  }
                  // Sort by order
                  final sortedPackages = List<PackageModel>.from(packages)
                    ..sort((a, b) => a.order.compareTo(b.order));

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedPackages.length + 1, // Add space in bottom
                    itemBuilder: (context, index) {
                      if (index == sortedPackages.length) {
                        return const SizedBox(height: 100); // 100px bottom spacing
                      }
                      final pkg = sortedPackages[index];
                      
                      String getTagLabel(String tag) {
                        if (tag == 'discount') return 'خصم';
                        if (tag == 'special') return 'خاصة';
                        return 'عادية';
                      }

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? AppColors.darkMuted : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pkg.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  if (pkg.tag != 'normal') ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: pkg.tag == 'discount' 
                                            ? AppColors.destructive.withValues(alpha: 0.1) 
                                            : AppColors.secondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        getTagLabel(pkg.tag),
                                        style: TextStyle(
                                          color: pkg.tag == 'discount' ? AppColors.destructive : AppColors.secondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: pkg.isActive
                                          ? AppColors.secondary.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      pkg.isActive ? 'نشط' : 'ملغى',
                                      style: TextStyle(
                                        color: pkg.isActive ? AppColors.secondary : Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (pkg.description.isNotEmpty) ...[
                                      Text(
                                        pkg.description,
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    Text('السعر: ${pkg.price.toString().toWesternDigits()} د.ل'),
                                    Text('المدة: ${pkg.durationValue.toString().toWesternDigits()} ${pkg.durationType == 'months' ? 'أشهر' : 'أسابيع'}'),
                                    Text('الحد الأقصى للاعبين: ${pkg.maxAthletes.toString().toWesternDigits()}'),
                                    if (pkg.department != null)
                                      departmentsAsync.when(
                                        data: (depts) {
                                          final dept = depts.firstWhere((d) => d.id == pkg.department, orElse: () => DepartmentModel(id: 0, name: '', nameAr: 'غير معروف', color: '#000', bankAccountNumber: '', iban: ''));
                                          return Text('الأكاديمية: ${dept.nameAr}');
                                        },
                                        loading: () => const SizedBox.shrink(),
                                        error: (e, s) => const SizedBox.shrink(),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.primary),
                                    onPressed: () => _showAddEditPackageDialog(pkg),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(pkg),
                                  ),
                                ],
                              ),
                            ),
                            if (pkg.features.isNotEmpty) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: pkg.features.map((feat) {
                                    return Chip(
                                      label: Text(
                                        feat,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const ShimmerList(),
                error: (e, st) => AppErrorWidget(
                  errorMessage: e.toString(),
                  onRetry: () => ref.refresh(packagesProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
