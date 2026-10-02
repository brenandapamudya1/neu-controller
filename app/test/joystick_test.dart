// M1c tests: joystick output range, deadzone, clamp, snap-back,
// and multi-touch with a button.
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/core/theme.dart';
import 'package:padlink/ui/widgets/neu_button.dart';
import 'package:padlink/ui/widgets/neu_joystick.dart';

/// Travel radius for defaults: (140 - 64) / 2 = 38 px.
const double _travel = (NeuSizes.stickBaseDefault - NeuSizes.stickKnobDefault) / 2;
const double _rest = _travel;

Future<Offset> _pumpJoystick(WidgetTester tester, List<Offset> outputs) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NeuJoystick(onChanged: outputs.add, haptic: false),
      ),
    ),
  );
  return tester.getCenter(find.byType(NeuJoystick));
}

void main() {
  testWidgets('joystick outputs -1..1 and reports zero on release',
      (tester) async {
    final List<Offset> outputs = <Offset>[];
    final Offset center = await _pumpJoystick(tester, outputs);

    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump();
    expect(outputs.last, Offset.zero); // down exactly at center

    // Half travel to the right -> x ~0.5.
    await gesture.moveBy(const Offset(_travel / 2, 0));
    await tester.pump();
    expect(outputs.last.dx, moreOrLessEquals(0.5));
    expect(outputs.last.dy, moreOrLessEquals(0.0));

    await gesture.up();
    await tester.pump();
    expect(outputs.last, Offset.zero);

    // Knob visual settles back to rest position.
    await tester.pumpAndSettle();
    final Positioned knob =
        tester.widget<Positioned>(find.byKey(const Key('neu-knob')));
    expect(knob.left, moreOrLessEquals(_rest));
    expect(knob.top, moreOrLessEquals(_rest));
  });

  testWidgets('deadzone swallows small deflections', (tester) async {
    final List<Offset> outputs = <Offset>[];
    final Offset center = await _pumpJoystick(tester, outputs);

    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump();
    // 2 px of 38 px travel ~0.05 < 0.08 deadzone.
    await gesture.moveBy(const Offset(2, 0));
    await tester.pump();
    expect(outputs.last, Offset.zero);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('deflection clamps at the travel radius', (tester) async {
    final List<Offset> outputs = <Offset>[];
    final Offset center = await _pumpJoystick(tester, outputs);

    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump();
    // Far beyond the edge -> clamped to unit magnitude.
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    expect(outputs.last.dx, moreOrLessEquals(1.0));
    expect(outputs.last.distance, moreOrLessEquals(1.0));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(outputs.last, Offset.zero);
  });

  testWidgets('joystick and button work simultaneously (multi-touch)',
      (tester) async {
    final List<Offset> stickOutputs = <Offset>[];
    final List<bool> buttonEvents = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              NeuJoystick(
                key: const Key('stick'),
                onChanged: stickOutputs.add,
                haptic: false,
              ),
              NeuButton.cross(
                key: const Key('cross'),
                onChanged: buttonEvents.add,
                haptic: false,
              ),
            ],
          ),
        ),
      ),
    );

    final TestGesture stick = await tester
        .startGesture(tester.getCenter(find.byKey(const Key('stick'))));
    await tester.pump();
    await stick.moveBy(const Offset(_travel / 2, 0));
    await tester.pump();
    final TestGesture button = await tester
        .startGesture(tester.getCenter(find.byKey(const Key('cross'))));
    await tester.pump();

    expect(stickOutputs.last.dx, moreOrLessEquals(0.5));
    expect(buttonEvents, <bool>[true]);

    await button.up();
    await tester.pump();
    expect(buttonEvents, <bool>[true, false]);
    // Stick still held at deflection.
    expect(stickOutputs.last.dx, moreOrLessEquals(0.5));

    await stick.up();
    await tester.pumpAndSettle();
    expect(stickOutputs.last, Offset.zero);
  });
}
