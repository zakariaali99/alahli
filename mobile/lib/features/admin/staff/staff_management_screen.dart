import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/widgets.dart';

final _usersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, search) async {
  return ref.watch(adminRepositoryProvider).getUsers(search: search);
});

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  Future<void> _showUserDialog({Map<String, dynamic>? existing}) async {
    final isEditing = existing != null;
    final nameArController = TextEditingController(text: existing?['first_name_ar'] as String? ?? '');
    final nameEnController = TextEditingController(text: existing?['last_name_ar'] as String? ?? '');
    final phoneController = TextEditingController(text: existing?['phone'] as String? ?? '');
    String selectedRole = existing?['role'] as String? ?? 'viewer';
    bool isActive = existing?['is_active'] as bool? ?? true;
    bool isSaving = false;

    final roles = [
      {'value': 'super_admin', 'label': 'سوبر أدمن', 'icon': Icons.admin_panel_settings, 'color': Colors.red},
      {'value': 'reception', 'label': 'موظف استقبال', 'icon': Icons.person, 'color': Colors.blue},
      {'value': 'trainer', 'label': 'مدرب', 'icon': Icons.fitness_center, 'color': Colors.green},
      {'value': 'viewer', 'label': 'مشاهد', 'icon': Icons.visibility, 'color': Colors.grey},
    ];

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'تعديل الموظف' : 'إضافة موظف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameArController,
                  decoration: const InputDecoration(labelText: 'الاسم الأول (عربي)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameEnController,
                  decoration: const InputDecoration(labelText: 'الاسم الأخير (عربي)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'الدور', border: OutlineInputBorder()),
                  items: roles.map((r) => DropdownMenuItem(
                    value: r['value'] as String,
                    child: Row(
                      children: [
                        Icon(r['icon'] as IconData, color: r['color'] as Color, size: 20),
                        const SizedBox(width: 8),
                        Text(r['label'] as String),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedRole = v ?? 'viewer'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('نشط'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameArController.text.trim().isEmpty || nameEnController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
                setDialogState(() => isSaving = true);
                try {
                  final data = {
                    'first_name_ar': nameArController.text.trim(),
                    'last_name_ar': nameEnController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'role': selectedRole,
                    'is_active': isActive,
                  };
                  final repo = ref.read(adminRepositoryProvider);
                  if (isEditing) {
                    await repo.updateUser(existing['id'] as int, data);
                  } else {
                    await repo.createUser(data);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ref.invalidate(_usersProvider(_searchQuery));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(isEditing ? 'تم تحديث الموظف' : 'تم إضافة الموظف'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setDialogState(() => isSaving = false);
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

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الموظف'),
        content: Text('هل تريد حذف "${user['first_name_ar']} ${user['last_name_ar']}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteUser(user['id'] as int);
      if (!mounted) return;
      ref.invalidate(_usersProvider(_searchQuery));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الموظف'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(_usersProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: () => _showUserDialog(), tooltip: 'إضافة موظف'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الهاتف...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      })
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.people_alt_outlined,
                    message: 'لا يوجد موظفين',
                    subtitle: 'اضغط على + لإضافة موظف جديد',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (ctx, i) {
                    final u = users[i];
                    final name = '${u['first_name_ar']} ${u['last_name_ar']}';
                    final role = u['role'] as String? ?? 'viewer';
                    final isActive = u['is_active'] as bool? ?? true;
                    final phone = u['phone'] as String? ?? '';
                    final roleInfo = _getRoleInfo(role);

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () => _showUserDialog(existing: u),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: roleInfo['color'].withValues(alpha: 0.15),
                            child: Icon(roleInfo['icon'], color: roleInfo['color']),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleInfo['color'].withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(roleInfo['label'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: roleInfo['color'])),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(phone, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _showUserDialog(existing: u);
                              if (v == 'delete') _deleteUser(u);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: isActive,
                            onChanged: (v) async {
                              try {
                                await ref.read(adminRepositoryProvider).updateUser(u['id'] as int, {'is_active': v});
                                ref.invalidate(_usersProvider(_searchQuery));
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: Colors.red));
                              }
                            },
                            activeColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(message: 'تعذر تحميل الموظفين: $e', onRetry: () => ref.invalidate(_usersProvider(_searchQuery))),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(String role) {
    switch (role) {
      case 'super_admin': return {'label': 'سوبر أدمن', 'icon': Icons.admin_panel_settings, 'color': Colors.red};
      case 'reception': return {'label': 'موظف استقبال', 'icon': Icons.person, 'color': Colors.blue};
      case 'trainer': return {'label': 'مدرب', 'icon': Icons.fitness_center, 'color': Colors.green};
      default: return {'label': 'مشاهد', 'icon': Icons.visibility, 'color': Colors.grey};
    }
  }
}