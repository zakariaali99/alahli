import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../core/theme/app_theme.dart';

class MembershipCardScreen extends ConsumerStatefulWidget {
  const MembershipCardScreen({super.key});

  @override
  ConsumerState<MembershipCardScreen> createState() => _MembershipCardScreenState();
}

class _MembershipCardScreenState extends ConsumerState<MembershipCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBrand = ref.watch(brandProvider);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          activeBrand == SportsBrand.alAhly ? 'مركز الأهلي الرياضي' : 'أكاديمية العوز',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            color: primaryColor,
            onPressed: () => context.go('/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCuNrY6dAhpL5FdfE9YvYydubOrX_RnwxZZc75u0Mfc-uwBi99ZNP4z6zGLtNKPRIF1OC9DEt51EULP4BABMCtnAusuoz9riCfsgPYpib8EZt3xHwWL_joaC92RK9_nh8CA-B53jvVYZaV-U_5Zl_ajx5VUYuTzkSPCuDqt8eYsbDMOH2GzA3Zy5QZhbzCtvPpDmxKYsNBY2C9kkvX02RPZwXsh_RScuxYacWbzvP-dvQ9mcszp2V5kCNyN24ko7kyaUrZQEoqgPTpX',
              ),
              onBackgroundImageError: (_, __) {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            // Section header
            const Column(
              children: [
                Text(
                  'البطاقة الرقمية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00288e),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'امسح الرمز للدخول إلى المرفق',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757684),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Premium Membership Card ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1a3668), Color(0xFF00204f)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00204f).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative glows
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2c694e).withOpacity(0.15),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'عضوية مميزة',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'مركز الأهلي الرياضي',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2c694e),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF95d4b3).withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF95d4b3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'نشط',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Member info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: const NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuCuNrY6dAhpL5FdfE9YvYydubOrX_RnwxZZc75u0Mfc-uwBi99ZNP4z6zGLtNKPRIF1OC9DEt51EULP4BABMCtnAusuoz9riCfsgPYpib8EZt3xHwWL_joaC92RK9_nh8CA-B53jvVYZaV-U_5Zl_ajx5VUYuTzkSPCuDqt8eYsbDMOH2GzA3Zy5QZhbzCtvPpDmxKYsNBY2C9kkvX02RPZwXsh_RScuxYacWbzvP-dvQ9mcszp2V5kCNyN24ko7kyaUrZQEoqgPTpX',
                              ),
                              onBackgroundImageError: (_, __) {},
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'أحمد محمد',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: AH-9876',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // QR Code area
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // QR Code visual simulation
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: Stack(
                                  children: [
                                    // QR grid pattern
                                    CustomPaint(
                                      size: const Size(180, 180),
                                      painter: QRCodePainter(),
                                    ),
                                    // Scanning line animation
                                    AnimatedBuilder(
                                      animation: _scanAnimation,
                                      builder: (context, child) {
                                        return Positioned(
                                          top: _scanAnimation.value * 170,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 2,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2c694e),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF2c694e)
                                                      .withOpacity(0.5),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'AH-9876-2024',
                                style: TextStyle(
                                  color: Color(0xFF747780),
                                  fontSize: 12,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.history,
                    label: 'سجل الدخول',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.help_outline,
                    label: 'مساعدة',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFc4c6d0).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00288e), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00288e),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom QR Code painter
class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF191c1d)
      ..style = PaintingStyle.fill;

    final rng = Random(42);
    const cellSize = 6.0;
    const cols = 28;
    const rows = 28;
    final offsetX = (size.width - cols * cellSize) / 2;
    final offsetY = (size.height - rows * cellSize) / 2;

    // Draw random QR-like pattern
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Corner finder patterns (7x7 squares at corners)
        bool isFinderPattern = _isFinderPattern(row, col, rows, cols);
        bool drawCell = isFinderPattern || rng.nextBool();
        if (drawCell) {
          canvas.drawRect(
            Rect.fromLTWH(
              offsetX + col * cellSize + 0.5,
              offsetY + row * cellSize + 0.5,
              cellSize - 1,
              cellSize - 1,
            ),
            paint,
          );
        }
      }
    }
  }

  bool _isFinderPattern(int row, int col, int rows, int cols) {
    // Top-left
    if (row < 7 && col < 7) {
      return (row == 0 || row == 6 || col == 0 || col == 6) ||
          (row >= 2 && row <= 4 && col >= 2 && col <= 4);
    }
    // Top-right
    if (row < 7 && col >= cols - 7) {
      int c = col - (cols - 7);
      return (row == 0 || row == 6 || c == 0 || c == 6) ||
          (row >= 2 && row <= 4 && c >= 2 && c <= 4);
    }
    // Bottom-left
    if (row >= rows - 7 && col < 7) {
      int r = row - (rows - 7);
      return (r == 0 || r == 6 || col == 0 || col == 6) ||
          (r >= 2 && r <= 4 && col >= 2 && col <= 4);
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
