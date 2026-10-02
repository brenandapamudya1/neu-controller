// M1a tests: theme tokens match DESIGN.md, NeuSurface toggles states.
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/core/theme.dart';
import 'package:padlink/ui/widgets/neu_surface.dart';

void main() {
  test('theme tokens match DESIGN.md', () {
    expect(NeuColors.bg, const Color(0xFFE0E5EC));
    expect(NeuColors.shadowLight, const Color(0xFFFFFFFF));
    expect(NeuColors.shadowDark, const Color(0xFFA3B1C6));
    expect(NeuColors.textMuted, const Color(0xFF6B7A90));
    expect(NeuColors.accent, const Color(0xFF5B8DEF));
    expect(NeuColors.cross, const Color(0xFF5B8DEF));
    expect(NeuColors.circle, const Color(0xFFE5484D));
    expect(NeuColors.square, const Color(0xFFD96FB0));
    expect(NeuColors.triangle, const Color(0xFF2EBD85));
    expect(NeuSizes.actionDefault, 60);
    expect(NeuSizes.minTouchTarget, 48);
    expect(NeuMotion.press.inMilliseconds, inInclusiveRange(60, 80));
  });

  testWidgets('NeuSurface raised has outer shadows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NeuSurface(
            width: 60,
            height: 60,
            child: Text('X'),
          ),
        ),
      ),
    );
    final container =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.boxShadow, isNotEmpty);
    expect(find.text('X'), findsOneWidget);
  });

  testWidgets('NeuSurface pressed drops shadows and shows inset',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NeuSurface.circle(
            diameter: 60,
            pressed: true,
            child: Text('X'),
          ),
        ),
      ),
    );
    // Let fade animation finish.
    await tester.pumpAndSettle();
    final container =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.boxShadow, isEmpty);
    expect(decoration.color, NeuColors.bgPressed);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
