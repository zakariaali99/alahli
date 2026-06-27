import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';

final _athletesProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, search) async {
  return ref.watch(adminRepositoryProvider).getAthletes(search: search.isNotEmpty ? search : null);
});

class SubscriberManagementScreen extends ConsumerStatefulWidget {
  const SubscriberManagementScreen({super.key});

  @override
  ConsumerState<SubscriberManagementScreen> createState() => _SubscriberManagementScreenState();
}

class _SubscriberManagementScreenState extends ConsumerState<SubscriberManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final athletesAsync = ref.watch(_athletesProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المشتركين'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddAthleteDialog(context),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('إضافة'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن مشترك...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() { _searchQuery = ''; _searchController.clear(); }),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_athletesProvider(_searchQuery));
              },
              child: athletesAsync.when(
                data: (data) {
                  final results = (data['results'] as List?) ?? [];
                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text('لا يوجد مشتركين', style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (ctx, i) {
                      final athlete = results[i] as Map<String, dynamic>;
                      return _buildMemberCard(theme, athlete);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      const Text('تعذر تحميل البيانات'),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: () => ref.invalidate(_athletesProvider(_searchQuery)), child: const Text('إعادة المحاولة')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAthleteDialog(BuildContext context) {
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final membersCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مشترك جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            TextField(controller: membersCtl, decoration: const InputDecoration(labelText: 'رقم العضوية', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtl.text.isEmpty || phoneCtl.text.isEmpty) return;
              try {
                await ref.read(adminRepositoryProvider).createAthlete({
                  'full_name': nameCtl.text.trim(),
                  'phone': phoneCtl.text.trim(),
                  'membership_number': membersCtl.text.trim(),
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ref.invalidate(_athletesProvider(_searchQuery));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المشترك'), backgroundColor: Colors.green));
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(ThemeData theme, Map<String, dynamic> athlete) {
    final id = athlete['id'] as int? ?? 0;
    final name = athlete['full_name'] as String? ?? '';
    final dept = athlete['department_name'] as String? ?? '';
    final isActive = athlete['is_active'] as bool? ?? true;
    final phone = athlete['phone'] as String? ?? '';
    final membersNum = athlete['membership_number'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => context.push('/admin/athlete/$id'),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(dept, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(phone, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 12),
                      Icon(Icons.tag, size: 12, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(membersNum, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(isActive ? 'نشط' : 'موقوف', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
