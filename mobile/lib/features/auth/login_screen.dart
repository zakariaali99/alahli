import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 9) {
      setState(() {
        _errorText = 'الرجاء إدخال رقم هاتف صحيح';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Mock API delay
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _isLoading = false;
      _otpSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال رمز التحقق التجريبي (123456) بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _verifyOtp() async {
    if (_otpController.text != '123456') {
      setState(() {
        _errorText = 'رمز التحقق غير صحيح، استخدم 123456';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Mock verification delay
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBrand = ref.watch(brandProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Sports Image
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAwa0uzV1b-vjPJOV-gLZo6lRXvrck75NQ72M3jfQAXu__4D-uQsPJEncFKW9qjWLT55l9-ny3TFJsy-qM9T8gWziF7sqL-pGb42l8o2RpYbprvJPlkOfN-7q_4PQB5_HQmgTdDokCHspvrkLdQw7Ch7cOL4s5kV_OClOAgvITRtUFt4HTOw6yovQYRNDkegiYZwzF6sk3QfT4-l--ylDMRWt8ECsAifyeUa8pi9B5HClHOURNQDzoNeUNmS9cha6C3XvDMATDABwk',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.65)),
          ),
          // Login Form Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCBfpzvwGK-Btr3vkVaDsTwIzQqeI6S__X6lWkXWbRX7HIg3mbGOB9yLTP3BD_lv95xjYRkkAyGNQbOgem92Fx23wG5-9Xewqs2mgq1CIQBophGNlMXB3hZtsmr0YbZ_frVz1fYI6pB_wAfx0tkMlF20P8xdopQyJd2VOjFWsPFTOYDukKe1jF6bHKoOZUtpjXU-kWh0fXTGQDSsXmvkHTeUtonGOsGMO6MbDgw0AhmmUKLhjufn6CGV5V_jexmYkg7qPWOa4iLFOQ',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تسجيل الدخول',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeBrand == SportsBrand.alAhly
                            ? 'مركز الأهلي الرياضي'
                            : 'أكاديمية العوز الرياضية',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_errorText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: theme.colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorText!,
                                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form content
                      if (!_otpSent) ...[
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textAlign: TextAlign.left,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            hintText: '091XXXXXXX',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('إرسال رمز التحقق'),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'رمز التحقق (OTP)',
                            hintText: '######',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('تأكيد الدخول'),
                        ),
                      ],

                      const SizedBox(height: 24),
                      // Toggles between Brands (Demo purposes)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('تغيير فرع العلامة التجارية: ', style: TextStyle(fontSize: 12)),
                          TextButton(
                            onPressed: () {
                              ref.read(brandProvider.notifier).state =
                                  activeBrand == SportsBrand.alAhly
                                      ? SportsBrand.awsAcademy
                                      : SportsBrand.alAhly;
                            },
                            child: Text(
                              activeBrand == SportsBrand.alAhly ? 'أكاديمية العوز' : 'نادي الأهلي',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
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
}
