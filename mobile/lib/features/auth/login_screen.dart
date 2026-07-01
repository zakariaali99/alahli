import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/helpers/numeral_converter.dart';
import '../../core/helpers/phone_validator.dart';
import '../../core/widgets/app_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim().toWesternDigits();
      final password = _passwordController.text;

      await ref.read(authProvider.notifier).login(phone, password, _rememberMe);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient blurs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF136F63).withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header / Intro section (stacked)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF0F4C81),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'منصة إدارة الأكاديمية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'تسجيل دخول آمن',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F4C81),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'سجّل الدخول للوصول إلى لوحة الإدارة أو لوحة المستخدم حسب صلاحية الحساب.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),

                    // Bullets list
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• تسجيل ذاتي للرياضي وولي الأمر', style: TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                        SizedBox(height: 4),
                        Text('• مسار اشتراك متعدد الخطوات', style: TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                        SizedBox(height: 4),
                        Text('• مراجعة واعتماد الطلبات عبر الإدارة', style: TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Form Glass Card
                    Form(
                      key: _formKey,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.destructive.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.destructive,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                labelText: 'رقم الهاتف',
                                hintText: '09xxxxxxxx',
                                prefixIcon: Icon(Icons.phone_android),
                              ),
                              validator: (val) => PhoneValidator.validateLibyanPhone(val) ?? (val == null || val.isEmpty ? 'يرجى إدخال رقم الهاتف' : null),
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال كلمة المرور' : null,
                            ),
                            const SizedBox(height: 12),

                            // Remember Me
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                ),
                                const Text(
                                  'تذكرني',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Submit button with gradient background container
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: isDark 
                                      ? [AppColors.darkPrimaryGradientStart, AppColors.darkPrimaryGradientEnd]
                                      : [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                                ),
                              ),
                              child: FilledButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text(
                                        'دخول',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Navigation to register screens
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/register/athlete'),
                          child: const Text(
                            'تسجيل رياضي',
                            style: TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('•', style: TextStyle(color: Colors.grey)),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register/parent'),
                          child: const Text(
                            'تسجيل ولي أمر',
                            style: TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

