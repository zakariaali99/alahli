import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MembershipDetailsScreen extends StatelessWidget {
  const MembershipDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock subscription history data
    final historyItems = [
      _SubscriptionItem(
        package: 'باقة 12 شهر',
        startDate: '20/05/2023',
        endDate: '20/05/2024',
        amount: '3,360 ر.س',
        status: 'نشط',
        isActive: true,
      ),
      _SubscriptionItem(
        package: 'باقة 6 أشهر',
        startDate: '20/11/2022',
        endDate: '20/05/2023',
        amount: '1,785 ر.س',
        status: 'منتهي',
        isActive: false,
      ),
      _SubscriptionItem(
        package: 'باقة 3 أشهر',
        startDate: '20/08/2022',
        endDate: '20/11/2022',
        amount: '945 ر.س',
        status: 'منتهي',
        isActive: false,
      ),
      _SubscriptionItem(
        package: 'شهر واحد',
        startDate: '01/07/2022',
        endDate: '01/08/2022',
        amount: '350 ر.س',
        status: 'منتهي',
        isActive: false,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'تفاصيل الاشتراك',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Membership Summary Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الاشتراك الحالي',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'باقة 12 شهر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2c694e),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoColumn('تاريخ البدء', '20/05/2023'),
                      _infoColumn('تاريخ الانتهاء', '20/05/2024'),
                      _infoColumn('المبلغ', '3,360 ر.س'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '165 يوم متبقي',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '54%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          value: 0.54,
                          backgroundColor: Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF95d4b3),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Renew button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.autorenew, size: 18),
                      label: const Text('تجديد الاشتراك الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // History section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'سجل الاشتراكات',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isActive
                          ? theme.colorScheme.primary.withOpacity(0.3)
                          : theme.colorScheme.outlineVariant.withOpacity(0.4),
                      width: item.isActive ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.isActive
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.outlineVariant.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.isActive
                              ? Icons.card_membership
                              : Icons.history,
                          color: item.isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.package,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isActive
                                        ? const Color(0xFF92f5a4)
                                        : const Color(0xFFe1e3e4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: item.isActive
                                          ? const Color(0xFF007233)
                                          : const Color(0xFF44474f),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.startDate} ← ${item.endDate}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.amount,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SubscriptionItem {
  final String package;
  final String startDate;
  final String endDate;
  final String amount;
  final String status;
  final bool isActive;

  _SubscriptionItem({
    required this.package,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.status,
    required this.isActive,
  });
}
