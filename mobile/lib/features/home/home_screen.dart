import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeBrand = ref.watch(brandProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeBrand == SportsBrand.alAhly ? 'مركز الأهلي الرياضي' : 'أكاديمية العوز',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.go('/notifications'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDGGWjdYMNAuEUlX3_EM-M5C_X614HuhQqcHXtUnmVNwOn2aqxNwXRB09c0OeQ6gxeSE7UazvUXA4Gjgy2hJUp-LfKNqbbVPm_77o2WuyzuqdCBpU67sTF3-J2D7CVq9ETiX9l2QMxRML3H4n3sWfSJ8UZh-NCco85SYTmIrveHsRx-2i0JNzQP02SdZEiVY4uN60EbtggO81P4E0E4wIf6-9zJbKHTkJTPMAVktn1AIXIK5XQTfDJZQz5oHgfIhNJ-rt9bOUbosws',
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBM5tjHTVLxtrPwaQgYjf_uPi9W2vtmQ9RpZILI2h-5wOOYcSAMSSB-lCYaU3MlO1nko9NS7wz4ChTV-TgeBjmCPQ_s438bx5CuEZKLouHXQzNcpUKy9LCtUwyXrEWHQaM58vxpnzOE36W9Tyb5UOhBn9WEQjDWwydewIco9hKMNxQ0ekkDd3M-6JZn2Qgd2URB2f4IQ0Ee7r_J0Mie2Yk0LRTidDtu9QE8VRdRxfGCv1thUzDwPBpsDnP-BPs0uLdhtzQh0jrY0CXS',
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، أحمد محمد',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeBrand == SportsBrand.alAhly ? 'نادي الأهلي للياقة' : 'أكاديمية العوز الرياضية',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hero Membership Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expiration & Active Status indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'حالة الاشتراك',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.secondaryContainer,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'نشط',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'تاريخ الانتهاء',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '2026-12-31',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Remaining Days & Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Text(
                        '45 يوم متبقي',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.secondaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/card'),
                        icon: const Icon(Icons.qr_code, size: 16),
                        label: const Text('عرض البطاقة', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          side: const BorderSide(color: Colors.white30, width: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Days Progress Indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.70, // 70% subscription left
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.secondaryContainer,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bento Actions Grid
            Text(
              'الإجراءات السريعة',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.25,
              children: [
                _buildBentoButton(
                  context,
                  icon: Icons.autorenew,
                  label: 'تجديد الاشتراك',
                  color: theme.colorScheme.primary,
                  onTap: () => context.push('/membership-details'),
                ),
                _buildBentoButton(
                  context,
                  icon: Icons.calendar_today,
                  label: 'جداول التمارين',
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جداول التمارين قريباً')),
                    );
                  },
                ),
                _buildBentoButton(
                  context,
                  icon: Icons.newspaper,
                  label: 'أخبار الأكاديمية',
                  color: Colors.amber[700]!,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('أخبار الأكاديمية قريباً')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
