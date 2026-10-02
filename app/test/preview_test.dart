// Preview-only golden: renders current M1 widgets to a PNG so the UI can
// be inspected without a device target (no Android SDK / Chrome here).
// This file is NOT a functional test. Regenerate with:
//   flutter test --update-goldens test/preview_test.dart
// Then open test/goldens/preview.png with an image viewer.
// NOTE: text uses the test font (blocks), shapes and colors are accurate.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/core/theme.dart';
import 'package:padlink/ui/controller_screen.dart';
import 'package:padlink/ui/widgets/neu_button.dart';
import 'package:padlink/ui/widgets/neu_joystick.dart';
import 'package:padlink/ui/widgets/shoulder_button.dart';

void main() {
  testWidgets('preview landscape widget board', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: NeuColors.bg,
          body: Center(
            child: SizedBox(
              width: 800,
              height: 360,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShoulderButton(kind: ShoulderKind.l2, haptic: false),
                      SizedBox(height: 12),
                      ShoulderButton(kind: ShoulderKind.l1, haptic: false),
                    ],
                  ),
                  NeuJoystick(haptic: false),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NeuButton.triangle(haptic: false),
                      SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeuButton.square(haptic: false),
                          SizedBox(width: 8),
                          NeuButton.cross(haptic: false),
                          SizedBox(width: 8),
                          NeuButton.circle(haptic: false),
                        ],
                      ),
                    ],
                  ),
                  NeuJoystick(haptic: false),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShoulderButton(kind: ShoulderKind.r2, haptic: false),
                      SizedBox(height: 12),
                      ShoulderButton(kind: ShoulderKind.r1, haptic: false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/preview.png'),
    );
  });

  testWidgets('preview full controller screen (landscape)', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerScreen(autoConnect: false),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ControllerScreen),
      matchesGoldenFile('goldens/controller.png'),
    );
  });

  testWidgets('preview dark controller screen', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: NeuTheme(
          palette: NeuPalette.dark,
          child: ControllerScreen(autoConnect: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ControllerScreen),
      matchesGoldenFile('goldens/controller_dark.png'),
    );
  });
}
