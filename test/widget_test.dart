// Basic smoke test for Riddles - Maths.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App title widget builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Riddles - Maths'))),
    );
    expect(find.text('Riddles - Maths'), findsOneWidget);
  });
}
