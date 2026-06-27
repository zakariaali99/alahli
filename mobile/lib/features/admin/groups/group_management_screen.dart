import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/widgets.dart';

final _departmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDepartments();
});

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  ConsumerState<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.blue;
    try {
      final hex = colorStr.replaceFirst('#', '0xFF');
      return Color(int.parse(hex));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _deleteDepartment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه المجموعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteDepartment(id);
      if (!mounted) return;
      ref.invalidate(_departmentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المجموعة'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red));
    }
  }

  void _showDepartmentDialog({Map<String, dynamic>? existing}) {
    final nameCtl = TextEditingController(text: existing?['name'] as String? ?? '');
    final nameArCtl = TextEditingController(text: existing?['name_ar'] as String? ?? '');
    final colorCtl = TextEditingController(text: existing?['color'] as String? ?? '#1487D4');
    final isEditing = existing != null;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'الاسم (إنجليزي)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: nameArCtl, decoration: const InputDecoration(labelText: 'الاسم (عربي)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: colorCtl, decoration: const InputDecoration(labelText: 'اللون (مثل #1E7A43)', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameCtl.text.trim().isEmpty) return;
                setDialogState(() => isSaving = true);
                try {
                  final data = {
                    'name': nameCtl.text.trim(),
                    'name_ar': nameArCtl.text.trim(),
                    'color': colorCtl.text.trim(),
                  };
                  final repo = ref.read(adminRepositoryProvider);
                  if (isEditing) {
                    await repo.updateDepartment(existing['id'] as int, data);
                  } else {
                    await repo.createDepartment(data);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ref.invalidate(_departmentsProvider);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red));
                  setDialogState(() => isSaving = false);
                }
              },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deptsAsync = ref.watch(_departmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجموعات الرياضية'),
        actions: [
          TextButton.icon(
            onPressed: () => _showDepartmentDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_departmentsProvider.future),
        child: deptsAsync.when(
          data: (departments) {
            if (departments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_outlined, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('لا توجد مجموعات', style: theme.textTheme.bodyLarge),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: departments.length,
              itemBuilder: (ctx, i) => _buildGroupCard(theme, departments[i]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                const Text('تعذر تحميل المجموعات'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => ref.invalidate(_departmentsProvider), child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(ThemeData theme, Map<String, dynamic> dept) {
    final id = dept['id'] as int? ?? 0;
    final name = dept['name'] as String? ?? '';
    final nameAr = dept['name_ar'] as String? ?? name;
    final color = _parseColor(dept['color'] as String?);
    final isActive = dept['is_active'] as bool? ?? true;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.sports_soccer, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nameAr, style: theme.textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(name, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _showDepartmentDialog(existing: dept);
              if (v == 'delete') _deleteDepartment(id);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
    );
  }
}
