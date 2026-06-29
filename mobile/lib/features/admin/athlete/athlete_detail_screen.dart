import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/helpers/numeral_converter.dart';

final _athleteDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  return ref.watch(adminRepositoryProvider).getAthleteDetail(id);
});

final _athleteSubscriptionsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, athleteId) async {
  final dio = ref.watch(apiClientProvider).dio;
  final r = await dio.get('/subscriptions/', queryParameters: {'athlete': athleteId});
  final list = (r.data as List?) ?? [];
  return list.map((e) => e as Map<String, dynamic>).toList();
});

class AthleteDetailScreen extends ConsumerStatefulWidget {
  final int athleteId;
  const AthleteDetailScreen({super.key, required this.athleteId});

  @override
  ConsumerState<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends ConsumerState<AthleteDetailScreen> {
  Future<void> _toggleActive(Map<String, dynamic> athlete) async {
    final id = athlete['id'] as int;
    final isActive = athlete['is_active'] as bool? ?? true;
    try {
      await ref.read(adminRepositoryProvider).updateAthlete(id, {'is_active': !isActive});
      if (!mounted) return;
      ref.invalidate(_athleteDetailProvider(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isActive ? 'تم إيقاف الحساب' : 'تم تفعيل الحساب')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final athleteAsync = ref.watch(_athleteDetailProvider(widget.athleteId));
    final subsAsync = ref.watch(_athleteSubscriptionsProvider(widget.athleteId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المشترك')),
      body: athleteAsync.when(
        data: (athlete) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_athleteDetailProvider(widget.athleteId));
            ref.invalidate(_athleteSubscriptionsProvider(widget.athleteId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(theme, athlete),
                const SizedBox(height: 20),
                _buildInfoSection(theme, athlete),
                const SizedBox(height: 20),
                _buildActions(theme, athlete),
                const SizedBox(height: 24),
                Text('سجل الاشتراكات', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                subsAsync.when(
                  data: (subs) {
                    if (subs.isEmpty) {
                      return const EmptyStateWidget(icon: Icons.card_membership_outlined, message: 'لا يوجد اشتراكات');
                    }
                    return Column(
                      children: subs.map((s) => _buildSubscriptionCard(theme, s)).toList(),
                    );
                  },
                  loading: () => const ShimmerList(itemCount: 2, itemHeight: 80),
                  error: (e, _) => AppErrorWidget(message: 'تعذر تحميل الاشتراكات', onRetry: () => ref.invalidate(_athleteSubscriptionsProvider(widget.athleteId))),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: 'تعذر تحميل بيانات المشترك', onRetry: () => ref.invalidate(_athleteDetailProvider(widget.athleteId))),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, Map<String, dynamic> athlete) {
    final name = athlete['full_name'] as String? ?? '';
    final isActive = athlete['is_active'] as bool? ?? true;
    final photo = athlete['photo'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
          begin: Alignment.topRight, end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: photo.isEmpty ? Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(isActive ? 'نشط' : 'موقوف', style: TextStyle(color: isActive ? Colors.green.shade200 : Colors.red.shade200, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, Map<String, dynamic> athlete) {
    final membership = NumeralConverter.convert(athlete['membership_number'] as String? ?? '—');
    final phone = NumeralConverter.convert(athlete['phone'] as String? ?? '—');
    final dept = athlete['department_name'] as String? ?? '—';
    final gender = athlete['gender'] as String? ?? '—';
    final birthDate = NumeralConverter.convert(athlete['birth_date'] as String? ?? '—');
    final notes = athlete['notes'] as String? ?? '';
    final createdAt = NumeralConverter.convert(athlete['created_at'] as String? ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _infoRow(theme, Icons.badge, 'رقم العضوية', membership),
          _infoRow(theme, Icons.phone, 'رقم الهاتف', phone),
          _infoRow(theme, Icons.fitness_center, 'القسم', dept),
          _infoRow(theme, Icons.wc, 'الجنس', gender == 'male' ? 'ذكر' : gender == 'female' ? 'أنثى' : gender),
          _infoRow(theme, Icons.cake, 'تاريخ الميلاد', birthDate),
          _infoRow(theme, Icons.calendar_today, 'تاريخ التسجيل', createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt),
          if (notes.isNotEmpty) _infoRow(theme, Icons.note, 'ملاحظات', notes),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme, Map<String, dynamic> athlete) {
    final isActive = athlete['is_active'] as bool? ?? true;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _toggleActive(athlete),
            icon: Icon(isActive ? Icons.pause_circle : Icons.check_circle, size: 18),
            label: Text(isActive ? 'إيقاف' : 'تفعيل'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isActive ? Colors.red : Colors.green,
              side: BorderSide(color: isActive ? Colors.red : Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(ThemeData theme, Map<String, dynamic> sub) {
    final packageName = sub['package_name'] as String? ?? '—';
    final status = sub['status'] as String? ?? '';
    final startDate = NumeralConverter.convert(sub['start_date'] as String? ?? '');
    final endDate = NumeralConverter.convert(sub['end_date'] as String? ?? '');
    final amount = NumeralConverter.convert(sub['amount'] as String? ?? '');
    final isActive = status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(packageName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(isActive ? 'نشط' : status, style: TextStyle(color: isActive ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(startDate, style: const TextStyle(fontSize: 12)),
              const Text(' ← ', style: TextStyle(fontSize: 12)),
              Text(endDate, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$amount د.ل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}
