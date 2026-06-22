import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_ahly_sports_center/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AlAhlyApp()));
    await tester.pump();
    expect(find.text('مركز الأهلي الرياضي'), findsWidgets);
  });
}
