// M1b tests: NeuButton down/up/cancel, multi-touch independence,
// ShoulderButton sizes/labels, glyph smoke test.
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/core/theme.dart';
import 'package:padlink/ui/widgets/action_glyph.dart';
import 'package:padlink/ui/widgets/neu_button.dart';
import 'package:padlink/ui/widgets/neu_surface.dart';
import 'package:padlink/ui/widgets/shoulder_button.dart';

void main() {
  testWidgets('NeuButton reports down then up', (tester) async {
    final List<bool> events = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeuButton.cross(onChanged: events.add, haptic: false),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(NeuButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump();
    expect(events, <bool>[true]);
    expect(
      tester.widget<NeuSurface>(find.byType(NeuSurface)).pressed,
      isTrue,
    );

    await gesture.up();
    await tester.pump();
    expect(events, <bool>[true, false]);
    expect(
      tester.widget<NeuSurface>(find.byType(NeuSurface)).pressed,
      isFalse,
    );
  });

  testWidgets('NeuButton cancel releases press', (tester) async {
    final List<bool> events = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeuButton.circle(onChanged: events.add, haptic: false),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(NeuButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump();
    expect(events, <bool>[true]);

    await gesture.cancel();
    await tester.pump();
    expect(events, <bool>[true, false]);
  });

  testWidgets('two NeuButtons work simultaneously (multi-touch)',
      (tester) async {
    final List<bool> crossEvents = <bool>[];
    final List<bool> circleEvents = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              NeuButton.cross(
                key: const Key('cross'),
                onChanged: crossEvents.add,
                haptic: false,
              ),
              NeuButton.circle(
                key: const Key('circle'),
                onChanged: circleEvents.add,
                haptic: false,
              ),
            ],
          ),
        ),
      ),
    );

    final TestGesture first =
        await tester.startGesture(tester.getCenter(find.byKey(const Key('cross'))));
    await tester.pump();
    final TestGesture second = await tester
        .startGesture(tester.getCenter(find.byKey(const Key('circle'))));
    await tester.pump();
    expect(crossEvents, <bool>[true]);
    expect(circleEvents, <bool>[true]);

    // Releasing one must not release the other.
    await first.up();
    await tester.pump();
    expect(crossEvents, <bool>[true, false]);
    expect(circleEvents, <bool>[true]);

    await second.up();
    await tester.pump();
    expect(circleEvents, <bool>[true, false]);
  });

  testWidgets('ShoulderButton sizes and labels match DESIGN.md',
      (tester) async {
    for (final MapEntry<ShoulderKind, List<dynamic>> entry in {
      ShoulderKind.l1: <dynamic>['L1', NeuSizes.l1r1Width, NeuSizes.l1r1Height],
      ShoulderKind.l2: <dynamic>['L2', NeuSizes.l2r2Width, NeuSizes.l2r2Height],
      ShoulderKind.r1: <dynamic>['R1', NeuSizes.l1r1Width, NeuSizes.l1r1Height],
      ShoulderKind.r2: <dynamic>['R2', NeuSizes.l2r2Width, NeuSizes.l2r2Height],
    }.entries) {
      final List<bool> events = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShoulderButton(
              kind: entry.key,
              onChanged: events.add,
              haptic: false,
            ),
          ),
        ),
      );
      expect(find.text(entry.value[0] as String), findsOneWidget);
      final NeuSurface surface = tester.widget<NeuSurface>(
        find.byType(NeuSurface),
      );
      expect(surface.width, entry.value[1] as double);
      expect(surface.height, entry.value[2] as double);

      final TestGesture gesture = await tester
          .startGesture(tester.getCenter(find.byType(ShoulderButton)));
      await tester.pump();
      expect(events, <bool>[true]);
      await gesture.up();
      await tester.pump();
      expect(events, <bool>[true, false]);
    }
  });

  testWidgets('all action glyphs paint without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ActionGlyph(kind: ActionGlyphKind.triangle, color: NeuColors.triangle),
              ActionGlyph(kind: ActionGlyphKind.circle, color: NeuColors.circle),
              ActionGlyph(kind: ActionGlyphKind.cross, color: NeuColors.cross),
              ActionGlyph(kind: ActionGlyphKind.square, color: NeuColors.square),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
