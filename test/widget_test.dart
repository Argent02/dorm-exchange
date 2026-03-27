import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic widget scaffold smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('DormExchange test scaffold'),
        ),
      ),
    );

    expect(find.text('DormExchange test scaffold'), findsOneWidget);
  });
}
