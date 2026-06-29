import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/models/subscription_model.dart';
import '../../../core/constants/api_endpoints.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  String? _selectedStatus;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getFilterParams() {
    return {
      'status': _selectedStatus,
      'search': _searchQuery,
    };
  }

  Future<void> _renewSub(SubscriptionModel sub) async {
    final monthsController = TextEditingController(text: '1');
    final amountController = TextEditingController(text: sub.amount.toString());
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تجديد الاشتراك للاعب', textAlign: TextAlign.right),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: 1,
                decoration: const InputDecoration(labelText: 'المدة (بالأشهر)'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('شهر واحد (1)')),
                  DropdownMenuItem(value: 3, child: Text('3 أشهر')),
                  DropdownMenuItem(value: 6, child: Text('6 أشهر')),
                  DropdownMenuItem(value: 12, child: Text('سنة كاملة (12)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    monthsController.text = val.toString();
                    // Auto-adjust price
                    amountController.text = (sub.amount / (sub.renewals.firstOrNull?.months ?? 1) * val).toString();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'القيمة المالية (د.ل)'),
                validator: (v) => v == null || v.isEmpty ? 'يرجى تحديد القيمة' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تجديد وتفعيل'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final months = int.parse(monthsController.text);
        final amount = double.parse(amountController.text.toWesternDigits());
        
        await ref.read(subscriptionRepositoryProvider).renewSubscription(
              id: sub.id,
              months: months,
              amount: amount,
            );
        ref.invalidate(subscriptionsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تجديد الاشتراك بنجاح وتمديد الصلاحية')),
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

  void _showDetailBottomSheet(SubscriptionModel sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sub.athleteName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('الباقة: ${sub.packageName}', style: const TextStyle(fontSize: 14)),
              Text('المبلغ المدفوع: ${NumberFormatter.formatCurrency(sub.amount)} د.ل', style: const TextStyle(fontSize: 14)),
              Text('بداية الاشتراك: ${sub.startDate.toWesternDigits()}', style: const TextStyle(fontSize: 14)),
              Text('نهاية الاشتراك: ${sub.endDate.toWesternDigits()}', style: const TextStyle(fontSize: 14)),
              Text('طريقة الدفع: ${sub.paymentMethod == 'cash' ? 'نقدي' : 'تحويل مصرفي'}', style: const TextStyle(fontSize: 14)),
              const Divider(height: 24),
              if (sub.invoicePdfUrl != null && sub.invoicePdfUrl!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    // Check if it is relative path or absolute
                    String url = sub.invoicePdfUrl!;
                    if (!url.startsWith('http')) {
                      url = '${ApiEndpoints.baseUrl}$url';
                    }
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('عرض الفاتورة / المستند المالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 8),
              if (sub.isExpired)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _renewSub(sub);
                  },
                  icon: const Icon(Icons.autorenew),
                  label: const Text('تجديد الاشتراك الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    final params = _getFilterParams();
    if (user?.role == 'academy_manager') {
      params['departmentId'] = user?.academy;
    }

    final subscriptionsAsync = ref.watch(subscriptionsProvider(params));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الاشتراكات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'بحث باسم اللاعب أو رقم العضوية...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip(null, 'الكل'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('active', 'نشط'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('expired', 'منتهي'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('pending', 'معلق'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('rejected', 'مرفوض'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Subscriptions list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(subscriptionsProvider(params)),
              child: subscriptionsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(message: 'لا توجد اشتراكات مطابقة للبحث');
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final sub = list[index];
                      return AppCard(
                        onTap: () => _showDetailBottomSheet(sub),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sub.athleteName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'الباقة: ${sub.packageName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                                    ),
                                  ),
                                  Text(
                                    'تاريخ الانتهاء: ${sub.endDate.toWesternDigits()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${NumberFormatter.formatCurrency(sub.amount)} د.ل',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusBadge(status: sub.status),
                                if (sub.isExpired) ...[
                                  const SizedBox(height: 8),
                                  IconButton(
                                    icon: const Icon(Icons.autorenew, color: AppColors.secondary),
                                    onPressed: () => _renewSub(sub),
                                    tooltip: 'تجديد الاشتراك',
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const ShimmerList(),
                error: (err, stack) => AppErrorWidget(
                  errorMessage: err.toString(),
                  onRetry: () => ref.refresh(subscriptionsProvider(params)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String? status, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedStatus == status,
      onSelected: (val) {
        setState(() {
          _selectedStatus = val ? status : null;
        });
      },
    );
  }
}
