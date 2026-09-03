import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmago_app/main.dart';

void main() {
  testWidgets('PharmaGo app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PharmaGoApp(),
      ),
    );
    // Pump past the splash screen timer to onboarding
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('PharmaGo'), findsNothing); // Navigated to onboarding
    expect(find.byType(PharmaGoApp), findsOneWidget);
  });
}
