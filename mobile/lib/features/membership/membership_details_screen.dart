import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/widgets.dart';

class MembershipDetailsScreen extends ConsumerStatefulWidget {
  const MembershipDetailsScreen({super.key});

  @override
  ConsumerState<MembershipDetailsScreen> createState() => _MembershipDetailsScreenState();
}

class _MembershipDetailsScreenState extends ConsumerState<MembershipDetailsScreen> {
  bool _isRenewing = false;
  int _selectedMonths = 1;

  Future<void> _handleRenew(int subId) async {
    final months = await _showMonthPicker();
    if (months == null || !mounted) return;
    setState(() => _isRenewing = true);
    try {
      await ref.read(subscriptionRepositoryProvider).renew(subId, months: months, amount: 150.0 * months);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تجديد الاشتراك بنجاح'), backgroundColor: Colors.green),
      );
      ref.invalidate(activeSubscriptionProvider);
      ref.invalidate(subscriptionsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التجديد: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRenewing = false);
    }
  }

  Future<int?> _showMonthPicker() {
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('مدة التجديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر عدد الأشهر'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [1, 3, 6, 12].map((m) {
                  final selected = _selectedMonths == m;
                  return ChoiceChip(
                    label: Text(m == 1 ? 'شهر' : '$m أشهر'),
                    selected: selected,
                    onSelected: (_) {
                      setDialogState(() => _selectedMonths = m);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('المبلغ: ${150 * _selectedMonths} د.ل', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, _selectedMonths), child: const Text('تأكيد')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSubAsync = ref.watch(activeSubscriptionProvider);
    final subscriptionsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراكات', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            activeSubAsync.when(
              data: (sub) {
                if (sub == null) return const SizedBox.shrink();
                return _buildActiveCard(context, theme, sub);
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(20),
                child: ShimmerLoading(height: 280),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text('تعذر تحميل الاشتراك', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(activeSubscriptionProvider),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'سجل التجديدات',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            subscriptionsAsync.when(
              data: (items) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildHistoryItem(theme, items[index]),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: ShimmerList(itemCount: 3, itemHeight: 72),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'تعذر تحميل سجل الاشتراكات',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCard(BuildContext context, ThemeData theme, dynamic sub) {
    final start = DateTime.tryParse(sub.startDate ?? '');
    final end = DateTime.tryParse(sub.endDate ?? '');
    final total = end != null && start != null ? end.difference(start).inDays : 365;
    final remaining = end != null ? end.difference(DateTime.now()).inDays : 0;
    final progress = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    final isExpired = remaining < 0;
    final progressPercent = ((1 - progress) * 100).round();
    final subId = sub.id as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryFixed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        sub.packageName ?? '—',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.star, color: theme.colorScheme.secondaryContainer, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الأيام المتبقية', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${isExpired ? 0 : remaining}',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'يوم',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildProgressRing(theme, progressPercent),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDateCard(
                      theme,
                      icon: Icons.calendar_today,
                      label: 'تاريخ البدء',
                      date: sub.startDate ?? '—',
                      iconColor: theme.colorScheme.secondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateCard(
                      theme,
                      icon: Icons.event_busy,
                      label: 'تاريخ الانتهاء',
                      date: sub.endDate ?? '—',
                      iconColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRenewing ? null : () => _handleRenew(subId),
                  icon: _isRenewing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.autorenew, size: 18),
                  label: Text(_isRenewing ? 'جاري التجديد...' : 'تجديد الاشتراك الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(ThemeData theme, int percent) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: percent / 100.0,
          trackColor: theme.colorScheme.primaryFixed.withValues(alpha: 0.3),
          progressColor: theme.colorScheme.secondaryContainer,
          strokeWidth: 4,
        ),
        child: Center(
          child: Icon(Icons.schedule, color: theme.colorScheme.secondaryContainer, size: 20),
        ),
      ),
    );
  }

  Widget _buildDateCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String date,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ThemeData theme, dynamic item) {
    final isActive = item.isActive;
    final amount = '${item.amount} د.ل';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.history,
              color: isActive ? theme.colorScheme.secondary : theme.colorScheme.outline,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.packageName ?? '—',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'نشط' : 'منتهي',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? theme.colorScheme.secondary : theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.startDate ?? ''} ← ${item.endDate ?? ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    Text(
                      amount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
