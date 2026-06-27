import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';

final _accountsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, search) async {
  final repo = ref.watch(adminRepositoryProvider);
  final res = await repo.getAthletes(search: search.isNotEmpty ? search : null);
  final results = (res['results'] as List?) ?? [];
  return results.map((e) => e as Map<String, dynamic>).toList();
});

class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _currentSearch => _searchController.text.trim();

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> accounts) {
    if (_selectedFilter == 0) return accounts;
    final wantActive = _selectedFilter == 1;
    return accounts.where((a) {
      final isActive = a['is_active'] as bool? ?? true;
      return wantActive == isActive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(_accountsProvider(_currentSearch));

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الحسابات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو رقم العضوية...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _currentSearch.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(theme, 'الكل', 0),
                const SizedBox(width: 8),
                _buildFilterChip(theme, 'نشط', 1),
                const SizedBox(width: 8),
                _buildFilterChip(theme, 'موقوف', 2),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_accountsProvider(_currentSearch));
              },
              child: accountsAsync.when(
                data: (accounts) {
                  final filtered = _applyFilter(accounts);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text('لا توجد حسابات', style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final acct = filtered[i];
                      return _buildAccountCard(theme, acct);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      const Text('تعذر تحميل الحسابات'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(_accountsProvider(_currentSearch)),
                        child: const Text('إعادة المحاولة'),
                      ),
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

  Widget _buildFilterChip(ThemeData theme, String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }

  Widget _buildAccountCard(ThemeData theme, Map<String, dynamic> acct) {
    final id = acct['id'] as int? ?? 0;
    final name = acct['full_name'] as String? ?? '';
    final phone = acct['phone'] as String? ?? '';
    final isActive = acct['is_active'] as bool? ?? true;
    final membership = acct['membership_number'] as String? ?? '';
    final department = acct['department_name'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: isActive ? theme.colorScheme.primary : Colors.red, width: 4)),
      ),
      child: InkWell(
        onTap: () => context.push('/admin/athlete/$id'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: theme.textTheme.titleMedium),
                        if (!isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Text('موقوف', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(phone, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    if (department.isNotEmpty)
                      Text(department, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    Text('رقم العضوية: $membership', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'suspend') {
                    try {
                      final repo = ref.read(adminRepositoryProvider);
                      await repo.updateAthlete(id, {'is_active': !isActive});
                      if (!mounted) return;
                      ref.invalidate(_accountsProvider(_currentSearch));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isActive ? 'تم إيقاف الحساب' : 'تم تفعيل الحساب')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل')])),
                  PopupMenuItem(value: 'suspend', child: Row(children: [Icon(Icons.pause_circle, size: 18), SizedBox(width: 8), Text(isActive ? 'إيقاف' : 'تفعيل')])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
