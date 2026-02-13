import 'package:flutter_test/flutter_test.dart';

import 'package:scibot/main.dart';

void main() {
  testWidgets('SciBot app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SciBot());

    // Verify the app loads
    expect(find.text('SciBot'), findsWidgets);
  });
}
