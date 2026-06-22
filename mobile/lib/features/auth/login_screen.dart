import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'مركز الأهلي الرياضي',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نظام إدارة الأداء الرياضي',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 48),

                // Phone field
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  enabled: authState.status != AuthStatus.loading,
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  enabled: authState.status != AuthStatus.loading,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 8),

                // Error message
                if (authState.status == AuthStatus.error)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.errorMessage ?? 'حدث خطأ',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.status == AuthStatus.loading ? null : _login,
                    child: authState.status == AuthStatus.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) return;
    ref.read(authStateProvider.notifier).login(phone, password);
  }
}
