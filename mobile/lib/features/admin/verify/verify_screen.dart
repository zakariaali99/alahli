import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/safe_json.dart';
import '../../../core/helpers/api_error_parser.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen>
    with WidgetsBindingObserver {
  final _manualController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _cameraError = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _scanResult;
  String? _errorMsg;
  bool _isCheckedIn = false;
  bool _isCameraStarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScanner());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualController.dispose();
    _stopScanner();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isScanning && !_cameraError) {
        _startScanner();
      }
    } else if (state == AppLifecycleState.paused) {
      _stopScanner();
    }
  }

  Future<void> _startScanner() async {
    if (_isScanning || _isCameraStarting) return;
    setState(() {
      _isCameraStarting = true;
      _cameraError = false;
    });
    try {
      final controller = MobileScannerController();
      await controller.start();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _scannerController = controller;
        _isScanning = true;
        _isCameraStarting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = true;
        _isScanning = false;
        _isCameraStarting = false;
      });
    }
  }

  Future<void> _stopScanner() async {
    try {
      await _scannerController?.stop();
    } catch (_) {}
    try {
      await _scannerController?.dispose();
    } catch (_) {}
    _scannerController = null;
    if (mounted) {
      setState(() {
        _isScanning = false;
        _isCameraStarting = false;
      });
    }
  }

  Future<void> _toggleScanner() async {
    if (_isScanning) {
      await _stopScanner();
    } else {
      await _startScanner();
    }
  }

  Future<void> _processVerification(String membershipNumber) async {
    setState(() {
      _isProcessing = true;
      _errorMsg = null;
      _scanResult = null;
      _isCheckedIn = false;
    });

    try {
      final repo = ref.read(athleteRepositoryProvider);
      final result = await repo.verifyMembership(membershipNumber.trim());

      setState(() {
        _scanResult = result;
      });

      // Auto check-in if subscription is active
      final isActive = asBool(result['active']) ?? false;
      final athleteId = asInt(result['athlete_id']);
      final subId = asInt(result['subscription_id']);

      if (isActive && athleteId != null) {
        final client = ref.read(apiClientProvider);
        await client.dio.post(
          '/attendance/',
          data: {
            'athlete': athleteId,
            'subscription': subId,
          },
        );
        setState(() {
          _isCheckedIn = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = parseApiError(e).message;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 124.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'الفحص السريع والتحقق من الهوية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isScanning
                          ? Icons.videocam
                          : _cameraError
                              ? Icons.videocam_off
                              : Icons.videocam,
                    ),
                    onPressed: _toggleScanner,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Camera scanner section
              if (_isCameraStarting)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_isScanning && !_cameraError)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && !_isProcessing) {
                        final code = barcodes.first.rawValue;
                        if (code != null) {
                          _processVerification(code);
                        }
                      }
                    },
                    errorBuilder: (context, error, child) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_cameraError) setState(() => _cameraError = true);
                      });
                      return child ?? const SizedBox.shrink();
                    },
                  ),
                )
              else
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _cameraError
                          ? AppColors.destructive.withValues(alpha: 0.5)
                          : AppColors.border,
                      width: 1.5,
                    ),
                    color: _cameraError
                        ? AppColors.destructive.withValues(alpha: 0.05)
                        : (isDark ? AppColors.darkCard : Colors.grey.shade50),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 20,
                          color: _cameraError
                              ? AppColors.destructive
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _cameraError
                              ? 'تعذر تشغيل الكاميرا'
                              : 'اضغط على أيقونة الكاميرا للتفعيل',
                          style: TextStyle(
                            color: _cameraError
                                ? AppColors.destructive
                                : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!_cameraError && _isScanning)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'وجّه الكاميرا نحو رمز QR على بطاقة العضوية',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              // Manual Entry section - always visible
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'التحقق اليدوي برقم العضوية',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualController,
                      onChanged: (_) => setState(() {}),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'رقم العضوية',
                        hintText: 'أدخل رقم العضوية للتحقق',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing || _manualController.text.trim().isEmpty
                            ? null
                            : () => _processVerification(_manualController.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isProcessing ? 'جاري التحقق...' : 'فحص',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Processing state
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Error display
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.destructive.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorMsg!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.destructive,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              // Scan Result Layout
              if (_scanResult != null) ...[
                const SizedBox(height: 12),
                _buildResultLayout(_scanResult!, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultLayout(Map<String, dynamic> result, bool isDark) {
    final name = asString(result['athlete_name']) ?? '';
    final code = asString(result['membership_number']) ?? '';
    final dept = asString(result['department']) ?? '';
    final active = asBool(result['active']) ?? false;
    final expiry = asString(result['expiry_date']) ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: active
            ? AppColors.secondary.withValues(alpha: 0.1)
            : AppColors.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.secondary : AppColors.destructive,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                active ? Icons.check_circle : Icons.dangerous,
                color: active ? AppColors.secondary : AppColors.destructive,
                size: 32,
              ),
              Text(
                active ? 'الاشتراك ساري المفعول' : 'الاشتراك منتهي الصلاحية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.secondary : AppColors.destructive,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'اسم اللاعب: $name',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'رقم العضوية: ${code.toWesternDigits()}',
            style: const TextStyle(fontSize: 13),
          ),
          if (dept.isNotEmpty)
            Text('الأكاديمية: $dept', style: const TextStyle(fontSize: 13)),
          if (expiry.isNotEmpty)
            Text(
              'تاريخ الانتهاء: ${expiry.toWesternDigits()}',
              style: const TextStyle(fontSize: 13),
            ),
          const SizedBox(height: 16),
          if (active && _isCheckedIn)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'تم تسجيل الحضور تلقائياً بنجاح',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
