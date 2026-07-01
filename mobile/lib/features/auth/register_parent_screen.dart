import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/constants/app_colors.dart';
import '../../core/helpers/phone_validator.dart';

class RegisterParentScreen extends ConsumerStatefulWidget {
  const RegisterParentScreen({super.key});

  @override
  ConsumerState<RegisterParentScreen> createState() => _RegisterParentScreenState();
}

class _RegisterParentScreenState extends ConsumerState<RegisterParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final birthDate = '${_yearController.text}-${_monthController.text.padLeft(2, '0')}-${_dayController.text.padLeft(2, '0')}';

      await apiClient.dio.post('/auth/register/', data: {
        'role': 'parent',
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'birth_date': birthDate,
      });

      setState(() {
        _success = true;
      });
    } catch (err) {
      setState(() {
        _error = 'فشل التسجيل. يرجى التأكد من البيانات أو أن الهاتف غير مسجل مسبقاً.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_success) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.secondary,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'تم التسجيل بنجاح',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يمكنك الآن تسجيل الدخول وإضافة الرياضيين الذين ترعاهم والاشتراك لهم.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedForeground, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                    ),
                    child: const Text('تسجيل الدخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل ولي أمر جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'أنشئ حساب ولي أمر لإدارة الرياضيين والاشتراكات',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  hintText: 'الاسم الأول والأخير',
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الاسم الكامل' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '09xxxxxxxx',
                ),
                validator: (val) => PhoneValidator.validateLibyanPhone(val) ?? (val == null || val.isEmpty ? 'يرجى إدخال رقم الهاتف' : null),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال كلمة المرور' : null,
              ),
              const SizedBox(height: 16),

              // Birthdate Grid
              const Text(
                'تاريخ الميلاد',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dayController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'يوم (DD)',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (val) {
                        final d = int.tryParse(val ?? '');
                        if (d == null || d < 1 || d > 31) return 'يوم خطأ';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _monthController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'شهر (MM)',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (val) {
                        final m = int.tryParse(val ?? '');
                        if (m == null || m < 1 || m > 12) return 'شهر خطأ';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'سنة (YYYY)',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (val) {
                        final y = int.tryParse(val ?? '');
                        final currentYear = DateTime.now().year;
                        if (y == null || y < 1900 || y > currentYear) return 'سنة خطأ';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.destructive, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],

              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تسجيل الحساب'),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لديك حساب بالفعل؟ ', style: TextStyle(color: AppColors.mutedForeground)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
