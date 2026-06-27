import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/models/trainer_model.dart';
import '../../core/widgets/widgets.dart';
import '../../core/models/review_model.dart';

class CoachProfileScreen extends ConsumerWidget {
  const CoachProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trainerAsync = ref.watch(trainerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المدرب', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: trainerAsync.when(
        data: (trainer) {
          if (trainer == null) return _buildNoData(theme);
          return _buildContent(context, theme, trainer, ref);
        },
        loading: () => const ShimmerList(),
        error: (_, __) => _buildError(theme),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, ThemeData theme, TrainerModel trainer, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Text(
              trainer.initials,
              style: TextStyle(fontSize: 28, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(trainer.fullNameAr,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(trainer.role, style: TextStyle(color: theme.colorScheme.outline, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBadge(theme, Icons.star, '${trainer.rating}', '${trainer.reviewsCount} تقييم'),
              _buildBadge(theme, Icons.workspace_premium, '${trainer.experienceYears}', 'سنوات خبرة'),
            ],
          ),
          if (trainer.bio.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Text('عن المدرب', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(trainer.bio, style: TextStyle(color: theme.colorScheme.outline, height: 1.6)),
          ],
          if (trainer.classes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Text('الحصص المتاحة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ...trainer.classes.map((c) => _buildClassCard(theme, c)),
          ],
          const SizedBox(height: 24),
          // Reviews section
          Align(
            alignment: Alignment.centerRight,
            child: Text('التقييمات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          reviewsAsync.when(
            data: (reviews) => reviews.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('لا توجد تقييمات بعد', style: TextStyle(color: theme.colorScheme.outline)),
                    ),
                  )
                : Column(
                    children: reviews.map((r) => _buildReviewCard(theme, r)).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ctx.push('/exercise-schedules'),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('حجز حصة'),
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
    );
  }

  Widget _buildBadge(ThemeData theme, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
      ],
    );
  }

  Widget _buildClassCard(ThemeData theme, TrainerClassModel cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cls.imageUrl.isNotEmpty)
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(image: NetworkImage(cls.imageUrl), fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cls.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cls.intensity, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.secondary)),
                    ),
                  ],
                ),
                if (cls.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(cls.description, style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cls.priceDisplay,
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 18)),
                    Text('${cls.durationMinutes} دقيقة',
                        style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoData(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('لا يوجد مدربون متاحون حالياً', style: TextStyle(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('تعذر تحميل بيانات المدرب', style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme, ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    )),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(review.comment, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
