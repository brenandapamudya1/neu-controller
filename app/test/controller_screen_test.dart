// M1d tests: controller screen wires every control to ControllerState.
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/core/input_state.dart';
import 'package:padlink/ui/controller_screen.dart';
import 'package:padlink/ui/widgets/action_glyph.dart';
import 'package:padlink/ui/widgets/neu_button.dart';
import 'package:padlink/ui/widgets/neu_dpad.dart';
import 'package:padlink/ui/widgets/neu_joystick.dart';
import 'package:padlink/ui/widgets/shoulder_button.dart';
import 'package:padlink/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _actionButton(ActionGlyphKind glyph) {
  return find.byWidgetPredicate(
    (Widget w) => w is NeuButton && w.glyph == glyph,
  );
}

Finder _shoulder(ShoulderKind kind) {
  return find.byWidgetPredicate(
    (Widget w) => w is ShoulderButton && w.kind == kind,
  );
}

Future<ControllerState> _pumpScreen(
  WidgetTester tester, {
  void Function()? onDisconnect,
  bool haptic = true,
  double deadzone = 0.08,
}) async {
  final ControllerState state = ControllerState();
  await tester.pumpWidget(
    MaterialApp(
      home: ControllerScreen(
        controller: state,
        autoConnect: false,
        onDisconnect: onDisconnect,
        haptic: haptic,
        deadzone: deadzone,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('screen contains the full control set', (tester) async {
    await _pumpScreen(tester);

    expect(find.byType(NeuButton), findsNWidgets(4));
    expect(find.byType(ShoulderButton), findsNWidgets(4));
    expect(find.byType(NeuJoystick), findsNWidgets(2));
    expect(find.byType(NeuDpad), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('disconnect button calls onDisconnect', (tester) async {
    bool called = false;
    await _pumpScreen(tester, onDisconnect: () => called = true);

    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('gear opens settings sheet', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final AppSettings settings = await AppSettings.load();
    final ControllerState state = ControllerState();
    await tester.pumpWidget(
      MaterialApp(
        home: ControllerScreen(
          controller: state,
          autoConnect: false,
          settings: settings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);
  });

  testWidgets('haptic and deadzone propagate to all controls',
      (tester) async {
    await _pumpScreen(tester, haptic: false, deadzone: 0.2);

    for (final NeuButton b in tester.widgetList<NeuButton>(
      find.byType(NeuButton),
    )) {
      expect(b.haptic, isFalse);
    }
    for (final ShoulderButton b in tester.widgetList<ShoulderButton>(
      find.byType(ShoulderButton),
    )) {
      expect(b.haptic, isFalse);
    }
    for (final NeuJoystick s in tester.widgetList<NeuJoystick>(
      find.byType(NeuJoystick),
    )) {
      expect(s.haptic, isFalse);
      expect(s.deadzone, 0.2);
    }
    expect(
      tester.widget<NeuDpad>(find.byType(NeuDpad)).haptic,
      isFalse,
    );
  });

  testWidgets('wide deadzone swallows small stick motion', (tester) async {
    final ControllerState state =
        await _pumpScreen(tester, deadzone: 0.5);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Left stick')),
    );
    await tester.pump();
    // 10 of 38 px travel ~0.26 < 0.5 deadzone.
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(state.value.lx, 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.value.lx, 0);
  });

  testWidgets('action button sets its bitmask bit', (tester) async {
    final ControllerState state = await _pumpScreen(tester);

    final TestGesture gesture = await tester
        .startGesture(tester.getCenter(_actionButton(ActionGlyphKind.cross)));
    await tester.pump();
    expect(state.value.buttons & PadButtons.cross, isNot(0));

    await gesture.up();
    await tester.pump();
    expect(state.value.buttons & PadButtons.cross, isZero);
  });

  testWidgets('left stick drag sets lx axis', (tester) async {
    final ControllerState state = await _pumpScreen(tester);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Left stick')),
    );
    await tester.pump();
    // Half travel (19 of 38 px) -> 0.5 * 127 rounds to 64.
    await gesture.moveBy(const Offset(19, 0));
    await tester.pump();
    expect(state.value.lx, 64);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.value.lx, 0);
  });

  testWidgets('L2 press sets trigger to 255', (tester) async {
    final ControllerState state = await _pumpScreen(tester);

    final TestGesture gesture = await tester
        .startGesture(tester.getCenter(_shoulder(ShoulderKind.l2)));
    await tester.pump();
    expect(state.value.l2, 255);

    await gesture.up();
    await tester.pump();
    expect(state.value.l2, 0);
  });

  testWidgets('D-pad up sets the dpad bit', (tester) async {
    final ControllerState state = await _pumpScreen(tester);

    final Offset origin = tester.getTopLeft(find.byType(NeuDpad));
    final TestGesture gesture =
        await tester.startGesture(origin + const Offset(75, 25));
    await tester.pump();
    expect(state.value.buttons & PadButtons.dpadUp, isNot(0));

    await gesture.up();
    await tester.pump();
    expect(state.value.buttons & PadButtons.dpadUp, isZero);
  });
}
