import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_ahly_sports_center/core/widgets/app_error_widget.dart';
import 'package:al_ahly_sports_center/core/widgets/empty_state.dart';
import 'package:al_ahly_sports_center/core/widgets/status_badge.dart';
import 'package:al_ahly_sports_center/core/widgets/staggered_list_item.dart';
import 'package:al_ahly_sports_center/core/helpers/ui_helpers.dart';

void main() {
  group('AppErrorWidget', () {
    testWidgets('renders error message and retry button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              errorMessage: 'خطأ في الاتصال',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('خطأ في الاتصال'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('retry button calls callback', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              errorMessage: 'خطأ',
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('إعادة المحاولة'));
      expect(retryCalled, true);
    });
  });

  group('EmptyState', () {
    testWidgets('renders message and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const EmptyState(message: 'لا توجد بيانات'),
          ),
        ),
      );

      expect(find.text('لا توجد بيانات'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders custom icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const EmptyState(message: 'فارغ', icon: Icons.inbox),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });
  });

  group('StatusBadge', () {
    testWidgets('shows correct label for active status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const StatusBadge(status: 'active'),
          ),
        ),
      );
      expect(find.text('نشط'), findsOneWidget);
    });

    testWidgets('shows correct label for expired status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const StatusBadge(status: 'expired'),
          ),
        ),
      );
      expect(find.text('منتهي'), findsOneWidget);
    });

    testWidgets('shows correct label for pending status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const StatusBadge(status: 'pending'),
          ),
        ),
      );
      expect(find.text('معلق'), findsOneWidget);
    });

    testWidgets('shows correct label for rejected status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const StatusBadge(status: 'rejected'),
          ),
        ),
      );
      expect(find.text('مرفوض'), findsOneWidget);
    });
  });

  group('UI Helpers', () {
    test('safeInitials handles null', () {
      expect(safeInitials(null), '?');
    });

    test('safeInitials handles empty string', () {
      expect(safeInitials(''), '?');
    });

    test('safeInitials handles single name', () {
      expect(safeInitials('أحمد'), isNotEmpty);
    });

    test('safeInitials handles full name', () {
      expect(safeInitials('أحمد علي'), isNotEmpty);
    });

    test('safeColor handles null', () {
      expect(safeColor(null), const Color(0xFF4183D9));
    });

    test('safeColor handles valid hex', () {
      expect(safeColor('#FF0000'), const Color(0xFFFF0000));
    });

    test('safeColor handles malformed hex', () {
      expect(safeColor('invalid'), const Color(0xFF4183D9));
    });

    test('safeDateTimeParse handles null', () {
      expect(safeDateTimeParse(null), isNull);
    });

    test('safeDateTimeParse handles empty string', () {
      expect(safeDateTimeParse(''), isNull);
    });

    test('safeDateTimeParse handles valid date', () {
      expect(safeDateTimeParse('2026-06-29T10:00:00Z'), isNotNull);
    });

    test('safeDateTimeParse handles invalid date', () {
      expect(safeDateTimeParse('not-a-date'), isNull);
    });
  });

  group('StaggeredListItem', () {
    testWidgets('renders child after animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredListItem(
              index: 0,
              child: const Text('Test Item'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test Item'), findsOneWidget);
    });
  });
}
