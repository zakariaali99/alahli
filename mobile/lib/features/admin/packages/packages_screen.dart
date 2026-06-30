import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/models/package_model.dart';
import 'package:go_router/go_router.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  void _showAddEditPackageDialog([PackageModel? package]) async {
    final nameController = TextEditingController(text: package?.name ?? '');
    final priceController = TextEditingController(text: package?.price.toString() ?? '');
    final typeController = TextEditingController(text: package?.durationType ?? 'months');
    final valueController = TextEditingController(text: package?.durationValue.toString() ?? '1');
    final athletesController = TextEditingController(text: package?.maxAthletes.toString() ?? '1');
    final formKey = GlobalKey<FormState>();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
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
                DropdownButtonFormField<String>(
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
                    if (val != null) typeController.text = val;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'قيمة المدة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
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
                const SizedBox(height: 24),
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
        ),
      ),
    );

    if (confirm == true) {
      try {
        final data = {
          'name': nameController.text.trim(),
          'price': double.parse(priceController.text.trim().toWesternDigits()),
          'duration_type': typeController.text,
          'duration_value': int.parse(valueController.text.trim().toWesternDigits()),
          'max_athletes': int.parse(athletesController.text.trim().toWesternDigits()),
          'is_active': true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الباقات', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPackageDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(packagesProvider),
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
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final pkg = packages[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? AppColors.darkMuted : AppColors.border,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('السعر: ${pkg.price.toString().toWesternDigits()} د.ل'),
                          Text('المدة: ${pkg.durationValue.toString().toWesternDigits()} ${pkg.durationType == 'months' ? 'أشهر' : 'أسابيع'}'),
                          Text('الحد الأقصى للاعبين: ${pkg.maxAthletes.toString().toWesternDigits()}'),
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
    );
  }
}
