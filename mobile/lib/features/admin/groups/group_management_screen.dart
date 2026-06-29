import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/helpers/numeral_converter.dart';

final _departmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDepartments();
});

final _sportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getSports();
});

final _groupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getGroups();
});

final _coachesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getUsers(role: 'trainer');
});

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  ConsumerState<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأكاديميات والمجموعات'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'الأكاديميات', icon: Icon(Icons.business)),
            Tab(text: 'الرياضات', icon: Icon(Icons.sports_soccer)),
            Tab(text: 'المجموعات', icon: Icon(Icons.groups)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _AcademiesTab(),
          const _SportsTab(),
          const _GroupsTab(),
        ],
      ),
    );
  }
}

// ================== ACADEMIES TAB ==================
class _AcademiesTab extends ConsumerStatefulWidget {
  const _AcademiesTab();

  @override
  ConsumerState<_AcademiesTab> createState() => _AcademiesTabState();
}

class _AcademiesTabState extends ConsumerState<_AcademiesTab> {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDepartmentDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_departmentsProvider.future),
        child: deptsAsync.when(
          data: (departments) {
            if (departments.isEmpty) {
              return const EmptyStateWidget(icon: Icons.business, message: 'لا توجد أكاديميات حالية');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: departments.length,
              itemBuilder: (ctx, i) {
                final dept = departments[i];
                final id = dept['id'] as int;
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
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.business, color: color, size: 24),
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
                                Container(
                                  width: 8,
                                  height: 8,
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
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorWidget(message: 'فشل تحميل الأكاديميات', onRetry: () => ref.invalidate(_departmentsProvider)),
        ),
      ),
    );
  }
}

// ================== SPORTS TAB ==================
class _SportsTab extends ConsumerStatefulWidget {
  const _SportsTab();

  @override
  ConsumerState<_SportsTab> createState() => _SportsTabState();
}

class _SportsTabState extends ConsumerState<_SportsTab> {
  Future<void> _deleteSport(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الرياضة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteSport(id);
      ref.invalidate(_sportsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الرياضة'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red));
    }
  }

  void _showSportDialog({Map<String, dynamic>? existing}) {
    final nameCtl = TextEditingController(text: existing?['name'] as String? ?? '');
    final nameArCtl = TextEditingController(text: existing?['name_ar'] as String? ?? '');
    int? selectedDeptId = existing?['department'] as int?;
    bool isActive = existing?['is_active'] as bool? ?? true;
    final isEditing = existing != null;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final deptsAsync = ref.watch(_departmentsProvider);

          return AlertDialog(
            title: Text(isEditing ? 'تعديل الرياضة' : 'إضافة رياضة جديدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'الاسم (إنجليزي)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: nameArCtl, decoration: const InputDecoration(labelText: 'الاسم (عربي)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  deptsAsync.when(
                    data: (depts) => DropdownButtonFormField<int>(
                      value: selectedDeptId,
                      decoration: const InputDecoration(labelText: 'الأكاديمية التابعة لها', border: OutlineInputBorder()),
                      items: depts.map((d) => DropdownMenuItem(value: d['id'] as int, child: Text(d['name_ar'] as String? ?? d['name'] as String? ?? ''))).toList(),
                      onChanged: (v) => setDialogState(() => selectedDeptId = v),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('خطأ في تحميل الأكاديميات: $e'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('نشط'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (nameCtl.text.trim().isEmpty || selectedDeptId == null) return;
                  setDialogState(() => isSaving = true);
                  try {
                    final data = {
                      'name': nameCtl.text.trim(),
                      'name_ar': nameArCtl.text.trim(),
                      'department': selectedDeptId,
                      'is_active': isActive,
                    };
                    final repo = ref.read(adminRepositoryProvider);
                    if (isEditing) {
                      await repo.updateSport(existing['id'] as int, data);
                    } else {
                      await repo.createSport(data);
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ref.invalidate(_sportsProvider);
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sportsAsync = ref.watch(_sportsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSportDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_sportsProvider.future),
        child: sportsAsync.when(
          data: (sports) {
            if (sports.isEmpty) {
              return const EmptyStateWidget(icon: Icons.sports_soccer, message: 'لا توجد رياضات حالية');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sports.length,
              itemBuilder: (ctx, i) {
                final sport = sports[i];
                final id = sport['id'] as int;
                final name = sport['name'] as String? ?? '';
                final nameAr = sport['name_ar'] as String? ?? name;
                final deptName = sport['department_name'] as String? ?? '';
                final isActive = sport['is_active'] as bool? ?? true;

                return AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.sports_soccer, color: theme.colorScheme.secondary, size: 24),
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
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('الأكاديمية: $deptName', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _showSportDialog(existing: sport);
                          if (v == 'delete') _deleteSport(id);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorWidget(message: 'فشل تحميل الرياضات', onRetry: () => ref.invalidate(_sportsProvider)),
        ),
      ),
    );
  }
}

// ================== GROUPS TAB ==================
class _GroupsTab extends ConsumerStatefulWidget {
  const _GroupsTab();

  @override
  ConsumerState<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<_GroupsTab> {
  final Map<String, String> _daysMap = {
    'saturday': 'السبت',
    'sunday': 'الأحد',
    'monday': 'الإثنين',
    'tuesday': 'الثلاثاء',
    'wednesday': 'الأربعاء',
    'thursday': 'الخميس',
    'friday': 'الجمعة',
  };

  Future<void> _deleteGroup(int id) async {
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
      await ref.read(adminRepositoryProvider).deleteGroup(id);
      ref.invalidate(_groupsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المجموعة'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red));
    }
  }

  void _showGroupDialog({Map<String, dynamic>? existing}) {
    final nameCtl = TextEditingController(text: existing?['name'] as String? ?? '');
    final nameArCtl = TextEditingController(text: existing?['name_ar'] as String? ?? '');
    int? selectedSportId = existing?['sport'] as int?;
    int? selectedCoachId = existing?['coach'] as int?;
    
    List<String> selectedDays = List<String>.from((existing?['days'] as List?) ?? []);
    
    // Time Strings
    String startTime = existing?['start_time'] as String? ?? '16:00:00';
    String endTime = existing?['end_time'] as String? ?? '18:00:00';
    
    bool isActive = existing?['is_active'] as bool? ?? true;
    final isEditing = existing != null;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final sportsAsync = ref.watch(_sportsProvider);
          final coachesAsync = ref.watch(_coachesProvider);

          return AlertDialog(
            title: Text(isEditing ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'اسم المجموعة (إنجليزي)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: nameArCtl, decoration: const InputDecoration(labelText: 'اسم المجموعة (عربي)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  sportsAsync.when(
                    data: (sports) => DropdownButtonFormField<int>(
                      value: selectedSportId,
                      decoration: const InputDecoration(labelText: 'الرياضة التابعة لها', border: OutlineInputBorder()),
                      items: sports.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['name_ar'] as String? ?? s['name'] as String? ?? ''))).toList(),
                      onChanged: (v) => setDialogState(() => selectedSportId = v),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('خطأ في تحميل الرياضات: $e'),
                  ),
                  const SizedBox(height: 8),
                  coachesAsync.when(
                    data: (coaches) => DropdownButtonFormField<int>(
                      value: selectedCoachId,
                      decoration: const InputDecoration(labelText: 'المدرب المسؤول', border: OutlineInputBorder()),
                      items: coaches.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['full_name_ar'] as String? ?? c['phone'] as String? ?? ''))).toList(),
                      onChanged: (v) => setDialogState(() => selectedCoachId = v),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('خطأ في تحميل المدربين: $e'),
                  ),
                  const SizedBox(height: 12),
                  
                  // Checklist of days
                  const Align(alignment: Alignment.centerRight, child: Text('أيام التمرين:', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _daysMap.entries.map((entry) {
                      final isSelected = selectedDays.contains(entry.key);
                      return FilterChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedDays.add(entry.key);
                            } else {
                              selectedDays.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  
                  // Time picking inputs
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: int.parse(startTime.split(':')[0]),
                                minute: int.parse(startTime.split(':')[1]),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => startTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00');
                            }
                          },
                          child: Text('البداية: ${NumeralConverter.convert(startTime.substring(0, 5))}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: int.parse(endTime.split(':')[0]),
                                minute: int.parse(endTime.split(':')[1]),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => endTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00');
                            }
                          },
                          child: Text('النهاية: ${NumeralConverter.convert(endTime.substring(0, 5))}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('نشط'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (nameCtl.text.trim().isEmpty || selectedSportId == null) return;
                  setDialogState(() => isSaving = true);
                  try {
                    final data = {
                      'name': nameCtl.text.trim(),
                      'name_ar': nameArCtl.text.trim(),
                      'sport': selectedSportId,
                      'coach': selectedCoachId,
                      'days': selectedDays,
                      'start_time': startTime,
                      'end_time': endTime,
                      'is_active': isActive,
                    };
                    final repo = ref.read(adminRepositoryProvider);
                    if (isEditing) {
                      await repo.updateGroup(existing['id'] as int, data);
                    } else {
                      await repo.createGroup(data);
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ref.invalidate(_groupsProvider);
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(_groupsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_groupsProvider.future),
        child: groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return const EmptyStateWidget(icon: Icons.groups, message: 'لا توجد مجموعات حالية');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (ctx, i) {
                final group = groups[i];
                final id = group['id'] as int;
                final name = group['name'] as String? ?? '';
                final nameAr = group['name_ar'] as String? ?? name;
                final sportName = group['sport_name'] as String? ?? '';
                final coachName = group['coach_name'] as String? ?? 'غير معين';
                final isActive = group['is_active'] as bool? ?? true;
                
                final daysList = (group['days'] as List?)?.map((d) => _daysMap[d.toString()] ?? d.toString()).join('، ') ?? '';
                final startTimeStr = NumeralConverter.convert((group['start_time'] as String? ?? '00:00').substring(0, 5));
                final endTimeStr = NumeralConverter.convert((group['end_time'] as String? ?? '00:00').substring(0, 5));

                return AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.groups, color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(nameAr, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('الرياضة: $sportName • المدرب: $coachName', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text('الأيام: $daysList', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text('التوقيت: $startTimeStr ← $endTimeStr', style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _showGroupDialog(existing: group);
                          if (v == 'delete') _deleteGroup(id);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorWidget(message: 'فشل تحميل المجموعات', onRetry: () => ref.invalidate(_groupsProvider)),
        ),
      ),
    );
  }
}
