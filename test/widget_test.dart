// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_agent/main.dart';

void main() {
  testWidgets('assistant welcome screen fits mobile and desktop layouts', (WidgetTester tester) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('NEXORA'), findsOneWidget);
      expect(find.textContaining('What can I take'), findsOneWidget);
      expect(find.text('Ask anything or give a Windows command...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
