import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/models/booking_model.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  final int? bookingId;

  const BookingConfirmationScreen({super.key, this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: bookingId == null
            ? _buildMissingBooking(context, theme)
            : FutureBuilder<BookingModel>(
                future: ref.read(bookingRepositoryProvider).getBooking(bookingId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _buildError(context, theme);
                  }
                  return _buildContent(context, theme, snapshot.data!);
                },
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, BookingModel booking) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: theme.colorScheme.secondary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'تم تأكيد الحجز!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'تم حجز الحصة بنجاح. يمكنك الاطلاع على تفاصيل الحجز أدناه.',
              style: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _detailRow(theme, Icons.fitness_center, 'نوع الحصة', booking.sessionName),
                  const Divider(height: 24),
                  _detailRow(theme, Icons.calendar_today, 'التاريخ', '${booking.date}, ${booking.time}'),
                  const Divider(height: 24),
                  _detailRow(theme, Icons.person, 'المدرب', booking.coachName),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت الإضافة إلى التقويم')),
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text('إضافة إلى التقويم'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.left),
        ),
      ],
    );
  }

  Widget _buildMissingBooking(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          const Text('لم يتم تحديد الحجز', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go('/'), child: const Text('العودة للرئيسية')),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          const Text('تعذر تحميل تفاصيل الحجز', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go('/'), child: const Text('العودة للرئيسية')),
        ],
      ),
    );
  }
}
