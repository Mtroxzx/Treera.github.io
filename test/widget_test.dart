// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:speedtest/main.dart';

void main() {
  testWidgets('Speedtest page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeedtestApp());

    expect(find.text('Speedtest'), findsOneWidget);
    expect(find.text('เช็กความเร็ว\nอินเทอร์เน็ต'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}
