import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/safe_json.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _manualController = TextEditingController();
  final _scannerController = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _scanResult;
  String? _errorMsg;
  bool _isCheckedIn = false;

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
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
        // Post to attendance log viewset
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
        _errorMsg = e.toString().replaceAll('Exception: ', '');
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
      appBar: AppBar(
        title: const Text('الفحص السريع والتحقق من الهوية', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.videocam_off : Icons.videocam),
            onPressed: () {
              setState(() {
                _isScanning = !_isScanning;
                if (_isScanning) {
                  _scannerController.start();
                } else {
                  _scannerController.stop();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scanner container
              if (_isScanning) ...[
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && !_isProcessing) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null) {
                          _processVerification(code);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Manual Entry field
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'التحقق اليدوي برقم العضوية',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  if (_manualController.text.isNotEmpty) {
                                    _processVerification(_manualController.text);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          child: const Text('فحص'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _manualController,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: 'مثال: ALA-XXXXXX',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
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
                    border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMsg!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              // Scan Result Layout
              if (_scanResult != null) ...[
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
        color: active ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.destructive.withValues(alpha: 0.1),
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
          Text('رقم العضوية: ${code.toWesternDigits()}', style: const TextStyle(fontSize: 13)),
          if (dept.isNotEmpty) Text('الأكاديمية: $dept', style: const TextStyle(fontSize: 13)),
          if (expiry.isNotEmpty) Text('تاريخ الانتهاء: ${expiry.toWesternDigits()}', style: const TextStyle(fontSize: 13)),
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
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
