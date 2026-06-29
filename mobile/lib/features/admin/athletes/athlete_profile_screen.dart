import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/paginated_providers.dart';

class AthleteProfileScreen extends ConsumerWidget {
  final int athleteId;

  const AthleteProfileScreen({required this.athleteId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athleteAsync = ref.watch(athleteDetailProvider(athleteId));
    final subscriptionsAsync = ref.watch(subscriptionsProvider(SubscriptionFilter(athleteId: athleteId)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الرياضي', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: athleteAsync.when(
        data: (athlete) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(athleteDetailProvider(athleteId));
              ref.invalidate(subscriptionsProvider(SubscriptionFilter(athleteId: athleteId)));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        Hero(
                          tag: 'athlete_avatar_${athlete.id}',
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: athlete.photo != null ? NetworkImage(athlete.photo!) : null,
                            child: athlete.photo == null
                                ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          athlete.fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'رقم العضوية: ${athlete.membershipNumber.toWesternDigits()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160, maxHeight: 160),
                            child: QrImageView(
                              data: athlete.membershipNumber,
                              version: QrVersions.auto,
                              size: 140.0,
                              gapless: false,
                              eyeStyle: const QrEyeStyle(
                                color: Colors.black,
                                eyeShape: QrEyeShape.square,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                color: Colors.black,
                                dataModuleShape: QrDataModuleShape.square,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'البيانات الشخصية',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('رقم الهاتف:', athlete.phone.toWesternDigits(), Icons.phone, context),
                        if (athlete.parentPhone != null && athlete.parentPhone!.isNotEmpty)
                          _buildInfoRow('رقم ولي الأمر:', athlete.parentPhone!.toWesternDigits(), Icons.supervised_user_circle, context),
                        if (athlete.birthDate != null)
                          _buildInfoRow('تاريخ الميلاد:', athlete.birthDate!.toWesternDigits(), Icons.cake, context),
                        _buildInfoRow('الجنس:', athlete.gender == 'male' ? 'ذكر' : 'أنثى', Icons.face, context),
                        if (athlete.departmentName != null)
                          _buildInfoRow('الأكاديمية/القسم:', athlete.departmentName!, Icons.business, context),
                        if (athlete.notes != null && athlete.notes!.isNotEmpty)
                          _buildInfoRow('ملاحظات:', athlete.notes!, Icons.note, context),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'سجل الاشتراكات والمستندات المالية',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),

                  subscriptionsAsync.when(
                    data: (subs) {
                      if (subs.isEmpty) {
                        return const AppCard(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('لا يوجد سجل اشتراكات مسبق لهذا اللاعب'),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: subs.length,
                        itemBuilder: (context, index) {
                          final sub = subs[index];
                          return AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.packageName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'تاريخ البداية: ${sub.startDate.toWesternDigits()}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'تاريخ الانتهاء: ${sub.endDate.toWesternDigits()}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'القيمة: ${NumberFormatter.formatCurrency(sub.amount)} د.ل',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                      ),
                                      if (sub.invoicePdfUrl != null && sub.invoicePdfUrl!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              String url = sub.invoicePdfUrl!;
                                              if (!url.startsWith('http')) {
                                                final origin = ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
                                                url = url.startsWith('/') ? '$origin$url' : '$origin/$url';
                                              }
                                              final uri = Uri.parse(url);
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            },
                                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                                            label: const Text('عرض الإيصال'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.primary,
                                              side: const BorderSide(color: AppColors.primary),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                StatusBadge(status: sub.status),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('خطأ في تحميل الاشتراكات: $e'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const ShimmerList(),
        error: (err, stack) => AppErrorWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.invalidate(athleteDetailProvider(athleteId)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
