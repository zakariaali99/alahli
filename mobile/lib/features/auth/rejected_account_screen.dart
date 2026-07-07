import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';

class RejectedAccountScreen extends ConsumerWidget {
  const RejectedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState == null || !authState.isRejectedRegistration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(Icons.cancel_outlined, size: 48, color: Colors.red.shade600),
                ),
                const SizedBox(height: 24),
                Text(
                  'تم رفض طلب التسجيل',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'لم يتم قبول طلب التسجيل الخاص بك. يمكنك حذف الحساب والمحاولة مرة أخرى.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سبب الرفض',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authState.registrationRejectionReason ?? 'غير محدد',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _DeleteButton(),
                const SizedBox(height: 16),
                _CreateNewButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends ConsumerState<_DeleteButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: _loading ? null : _handleDelete,
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_outline),
      label: Text('حذف الحساب والتسجيل من جديد'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Future<void> _handleDelete() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).deleteRejectedAccount();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _CreateNewButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateNewButton> createState() => _CreateNewButtonState();
}

class _CreateNewButtonState extends ConsumerState<_CreateNewButton> {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _handleCreateNew,
      icon: const Icon(Icons.person_add_outlined),
      label: Text('إنشاء حساب جديد'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFF102033), width: 1.5),
        foregroundColor: const Color(0xFF102033),
      ),
    );
  }

  Future<void> _handleCreateNew() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/');
  }
}
