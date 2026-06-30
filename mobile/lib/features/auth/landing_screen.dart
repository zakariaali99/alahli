import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
                color: const Color(0xFF0F4C81).withValues(alpha: 0.12),
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
                color: const Color(0xFF136F63).withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Scrollable content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top AppBar
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4C81),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'منصة الأكاديمية الرياضية',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.foreground,
                            ),
                          ),
                          const Text(
                            'إدارة التسجيل والاشتراكات',
                            style: TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.push('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0F4C81),
                      ),
                      child: const Text('دخول', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // Hero & Features list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Hero Badge
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0F4C81).withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: Color(0xFF0F4C81), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'منصة رقمية متكاملة للأكاديميات',
                                style: TextStyle(
                                  color: Color(0xFF0F4C81),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        'إدارة التسجيل والاشتراكات',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: isDark ? Colors.white : AppColors.foreground,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF0F4C81), Color(0xFF136F63)],
                        ).createShader(bounds),
                        child: Text(
                          'بتجربة فاخرة وسريعة',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'نظام شامل يربط بين الرياضي وولي الأمر والإدارة ضمن تدفق واضح: من التسجيل بالكاميرا إلى اعتماد الاشتراك وإدارة التنبيهات.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA Buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => context.push('/register/athlete'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F4C81),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('ابدأ كرياضي'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_back, size: 16), // RTL arrow back is leftwards
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/register/parent'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF136F63),
                                side: const BorderSide(color: Color(0xFF136F63), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: const Text('ابدأ كولي أمر'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Features grid (3 cards)
                      _buildFeatureCard(
                        icon: Icons.bolt,
                        title: 'تسجيل ذاتي فوري',
                        body: 'إنشاء حساب رياضي أو ولي أمر خلال دقائق مع تدفق واضح ومباشر.',
                      ),
                      _buildFeatureCard(
                        icon: Icons.calendar_month,
                        title: 'اشتراك متعدد الخطوات',
                        body: 'أكاديمية ← رياضة ← مجموعة ← باقة ← دفع. كل خطوة مفهومة وسريعة.',
                      ),
                      _buildFeatureCard(
                        icon: Icons.shield_outlined,
                        title: 'إدارة احترافية',
                        body: 'لوحة إدارية لمراجعة الطلبات، إدارة الباقات، الأكاديميات، والتنبيهات.',
                      ),
                      const SizedBox(height: 24),

                      // Tracks section (Center of Fitness & Academy)
                      _buildTrackCard(
                        icon: Icons.fitness_center,
                        title: 'مركز اللياقة',
                        subtitle: 'تدريب بدني متكامل',
                        points: ['برامج قوة وتحمل', 'خطط متابعة شهرية', 'إشراف مدربين متخصصين'],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F4C81), Color(0xFF1F6AA5)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTrackCard(
                        icon: Icons.emoji_events,
                        title: 'أكاديمية المهارات',
                        subtitle: 'تطوير فني وذهني',
                        points: ['مجموعات حسب المستوى', 'جداول أيام وأوقات مرنة', 'تقييم أداء دوري'],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF136F63), Color(0xFF1E9A8A)],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Footer Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFooterItem(
                              icon: Icons.business,
                              title: 'إدارة الأكاديميات',
                              body: 'إنشاء الأكاديميات والرياضات والمجموعات وربطها بالمدربين.',
                              color: const Color(0xFF0F4C81),
                            ),
                            const Divider(height: 32),
                            _buildFooterItem(
                              icon: Icons.verified_user_outlined,
                              title: 'اعتمادات آمنة',
                              body: 'كل حساب جديد يبقى Pending حتى الاشتراك والموافقة الإدارية.',
                              color: const Color(0xFF136F63),
                            ),
                            const Divider(height: 32),
                            _buildFooterItem(
                              icon: Icons.access_time,
                              title: 'تنبيهات انتهاء الاشتراكات',
                              body: 'عرض فوري للاشتراكات المنتهية والقريبة من الانتهاء.',
                              color: const Color(0xFFC62828),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bolt,
              color: Color(0xFF0F4C81),
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> points,
    required Gradient gradient,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: gradient,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white.withValues(alpha: 0.4),
            child: Column(
              children: points.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF136F63), size: 16),
                      const SizedBox(width: 10),
                      Text(
                        p,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
