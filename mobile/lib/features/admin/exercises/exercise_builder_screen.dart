import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';

final _exercisesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getExercises();
});

class ExerciseBuilderScreen extends ConsumerStatefulWidget {
  const ExerciseBuilderScreen({super.key});

  @override
  ConsumerState<ExerciseBuilderScreen> createState() => _ExerciseBuilderScreenState();
}

class _ExerciseBuilderScreenState extends ConsumerState<ExerciseBuilderScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _durationController = TextEditingController();
  String _difficulty = 'medium';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم التمرين')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminRepositoryProvider).createExercise({
        'title': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'calories': int.tryParse(_caloriesController.text) ?? 0,
        'duration_minutes': int.tryParse(_durationController.text) ?? 30,
        'difficulty': _difficulty,
      });
      _nameController.clear();
      _descController.clear();
      _caloriesController.clear();
      _durationController.clear();
      if (!mounted) return;
      ref.invalidate(_exercisesProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة التمرين بنجاح'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteExercise(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا التمرين؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteExercise(id);
      if (!mounted) return;
      ref.invalidate(_exercisesProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف التمرين'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(_exercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('بناء التمارين')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_exercisesProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('إضافة تمرين جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم التمرين', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'السعرات الحرارية', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'المدة (دقيقة)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(labelText: 'الصعوبة', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('سهل')),
                DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                DropdownMenuItem(value: 'hard', child: Text('صعب')),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _addExercise,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('إضافة التمرين'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('التمارين المضافة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.fitness_center, size: 40, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text('لا توجد تمارين مضافة بعد', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: exercises.map((e) => _buildExerciseItem(theme, e)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
                    const SizedBox(height: 8),
                    Text('خطأ في تحميل التمارين: $err'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(ThemeData theme, Map<String, dynamic> e) {
    final id = e['id'] as int? ?? 0;
    final title = e['title'] as String? ?? '';
    final difficulty = e['difficulty'] as String? ?? 'medium';
    final duration = e['duration_minutes'] as int? ?? 0;

    final diffLabel = difficulty == 'easy' ? 'سهل' : difficulty == 'hard' ? 'صعب' : 'متوسط';
    final diffColor = difficulty == 'easy' ? Colors.green : difficulty == 'hard' ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(diffLabel, style: TextStyle(fontSize: 10, color: diffColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text('$duration دقيقة', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
            onPressed: () => _deleteExercise(id),
          ),
        ],
      ),
    );
  }
}
