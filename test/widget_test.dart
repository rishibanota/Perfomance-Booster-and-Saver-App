import 'package:flutter_test/flutter_test.dart';
import 'package:perfomance_booster_and_saver_app/main.dart';

void main() {
  testWidgets('Performance Booster App smoke test', (WidgetTester tester) async {
    // Build app and trigger a frame
    await tester.pumpWidget(const PerformanceBoosterApp());

    // Verify app title or core components render
    expect(find.text('Optimizer & Saver'), findsOneWidget);
  });
}
