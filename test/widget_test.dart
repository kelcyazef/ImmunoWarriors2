// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:immunowarriors/main.dart';

void main() {
  testWidgets('ImmunoWarriors app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ImmunoWarriorsApp());

    // Verify that the app doesn't crash and some basic elements are present
    // Just checking for the 'Immunowarriors' text somewhere in the app or login screen
    // This is a simple smoke test - we just want to make sure the app builds and renders
    expect(find.textContaining('Immuno', findRichText: true), findsWidgets);
  });
}
