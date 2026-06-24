import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';

class SubscriptionVerificationScreen extends ConsumerWidget {
  const SubscriptionVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeSubAsync = ref.watch(activeSubscriptionProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.primary.withValues(alpha: 0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: activeSubAsync.when(
                      data: (sub) => sub != null
                          ? _buildContent(theme, sub)
                          : _buildNoSubscription(theme),
                      loading: () => _buildLoading(theme),
                      error: (_, __) => _buildError(theme),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home),
                      label: const Text('العودة للرئيسية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, dynamic sub) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.check_circle, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 20),
        const Text(
          'الاشتراك نشط',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'تم التحقق من عضويتك بنجاح. يمكنك استخدام البطاقة الرقمية للدخول إلى المرفق الرياضي.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _detailRow('نوع العضوية', sub.packageName ?? '—', Icons.workspace_premium),
              const Divider(color: Colors.white24, height: 20),
              _detailRow('تاريخ الانتهاء', sub.endDate, Icons.calendar_today),
              const Divider(color: Colors.white24, height: 20),
              _detailRow('رقم العضوية', sub.membershipNumber, Icons.credit_card),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoSubscription(ThemeData theme) {
    return const Column(
      children: [
        Icon(Icons.cancel, color: Colors.white70, size: 48),
        SizedBox(height: 16),
        Text(
          'لا يوجد اشتراك نشط',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildError(ThemeData theme) {
    return const Column(
      children: [
        Icon(Icons.error_outline, color: Colors.white70, size: 48),
        SizedBox(height: 16),
        Text(
          'تعذر التحقق من الاشتراك',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
