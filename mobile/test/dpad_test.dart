// M1d tests: D-pad arms, slide, diagonals, dead center, release.
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/ui/widgets/neu_dpad.dart';

Future<Offset> _pumpDpad(
  WidgetTester tester,
  List<Set<DpadDirection>> events,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NeuDpad(onChanged: events.add, haptic: false),
      ),
    ),
  );
  return tester.getTopLeft(find.byType(NeuDpad));
}

void main() {
  testWidgets('D-pad arm press and release', (tester) async {
    final List<Set<DpadDirection>> events = <Set<DpadDirection>>[];
    final Offset origin = await _pumpDpad(tester, events);

    // Up arm center: (75, 25).
    final TestGesture gesture =
        await tester.startGesture(origin + const Offset(75, 25));
    await tester.pump();
    expect(events.last, {DpadDirection.up});

    await gesture.up();
    await tester.pump();
    expect(events.last, isEmpty);
  });

  testWidgets('sliding finger changes arms, corners give diagonals',
      (tester) async {
    final List<Set<DpadDirection>> events = <Set<DpadDirection>>[];
    final Offset origin = await _pumpDpad(tester, events);

    final TestGesture gesture =
        await tester.startGesture(origin + const Offset(75, 25));
    await tester.pump();
    expect(events.last, {DpadDirection.up});

    // Slide to right arm center: (125, 75).
    await gesture.moveTo(origin + const Offset(125, 75));
    await tester.pump();
    expect(events.last, {DpadDirection.right});

    // Slide to top-right corner: diagonal up + right.
    await gesture.moveTo(origin + const Offset(125, 25));
    await tester.pump();
    expect(events.last, {DpadDirection.up, DpadDirection.right});

    await gesture.up();
    await tester.pump();
    expect(events.last, isEmpty);
  });

  testWidgets('dead center reports nothing', (tester) async {
    final List<Set<DpadDirection>> events = <Set<DpadDirection>>[];
    final Offset origin = await _pumpDpad(tester, events);

    final TestGesture gesture =
        await tester.startGesture(origin + const Offset(75, 75));
    await tester.pump();
    expect(events, isEmpty);

    await gesture.up();
    await tester.pump();
    expect(events, isEmpty);
  });
}
