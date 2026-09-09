import 'package:flutter_test/flutter_test.dart';

import 'package:wahniorderapp/main.dart';

void main() {
  testWidgets('Placeholder app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WahniOrderApp());

    expect(find.text('Wahni Order App - Initial Setup'), findsOneWidget);
  });
}
