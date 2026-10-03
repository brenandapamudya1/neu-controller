// M3a tests: StatusPill colors and labels (DESIGN.md 5.3).
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/core/theme.dart';
import 'package:padlink/ui/widgets/status_pill.dart';

Color _dotColor(WidgetTester tester) {
  final Iterable<Container> dots =
      tester.widgetList<Container>(find.byType(Container));
  for (final Container dot in dots) {
    final Decoration? decoration = dot.decoration;
    if (decoration is BoxDecoration && decoration.shape == BoxShape.circle) {
      return decoration.color!;
    }
  }
  fail('no status dot found');
}

void main() {
  testWidgets('null shows red Disconnected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusPill(rttMs: null))),
    );
    expect(find.text('Disconnected'), findsOneWidget);
    expect(_dotColor(tester), NeuPalette.light.error);
  });

  testWidgets('12 ms shows green Connected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusPill(rttMs: 12))),
    );
    expect(find.text('Connected · 12 ms'), findsOneWidget);
    expect(_dotColor(tester), NeuPalette.light.ok);
  });

  testWidgets('45 ms shows yellow Slow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusPill(rttMs: 45))),
    );
    expect(find.text('Slow · 45 ms'), findsOneWidget);
    expect(_dotColor(tester), NeuPalette.light.warn);
  });
}
