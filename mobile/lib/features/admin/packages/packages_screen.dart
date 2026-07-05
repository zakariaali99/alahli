import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/permissions.dart';
import '../../../core/helpers/api_error_parser.dart';
import '../../../core/models/package_model.dart';
import '../../../core/models/department_model.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  Future<void> _navigateToAddEdit([PackageModel? package]) async {
    late final String path;
    if (package == null) {
      path = '/dashboard/packages/add';
    } else {
      path = '/dashboard/packages/${package.id}/edit';
    }
    final result = await context.push<bool>(path);
    if (result == true) ref.invalidate(packagesProvider);
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
          final parsed = parseApiError(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(parsed.message)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(packagesProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      floatingActionButton: Permissions.can(user?.role, AppAction.packagesCreate)
          ? FloatingActionButton(
              onPressed: () => _navigateToAddEdit(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
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

                      return AppCard(
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
                                        error: (e, s) => TextButton.icon(
                                          icon: const Icon(Icons.refresh, size: 16),
                                          label: const Text('فشل التحميل، اضغط لإعادة المحاولة', style: TextStyle(fontSize: 12)),
                                          onPressed: () => ref.invalidate(departmentsProvider),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (Permissions.can(user?.role, AppAction.packagesUpdate))
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primary),
                                      onPressed: () => _navigateToAddEdit(pkg),
                                    ),
                                  if (Permissions.can(user?.role, AppAction.packagesDelete))
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
