// M2c tests: NeuTheme fallback, dark palette driving surfaces.
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/core/theme.dart';
import 'package:padlink/ui/widgets/neu_surface.dart';

BoxDecoration _surfaceDecoration(WidgetTester tester) {
  return tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
      as BoxDecoration;
}

void main() {
  testWidgets('NeuTheme falls back to light when absent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NeuSurface(width: 60, height: 60)),
      ),
    );
    expect(_surfaceDecoration(tester).color, NeuPalette.light.bg);
  });

  testWidgets('dark palette drives pressed surface color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NeuTheme(
          palette: NeuPalette.dark,
          child: Scaffold(
            body: NeuSurface(width: 60, height: 60, pressed: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_surfaceDecoration(tester).color, NeuPalette.dark.bgPressed);
  });

  testWidgets('dark raised shadows use dark tokens', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NeuTheme(
          palette: NeuPalette.dark,
          child: Scaffold(body: NeuSurface(width: 60, height: 60)),
        ),
      ),
    );
    final List<BoxShadow> shadows =
        _surfaceDecoration(tester).boxShadow ?? const [];
    expect(shadows, isNotEmpty);
    expect(
      shadows.map((BoxShadow s) => s.color),
      containsAll([
        NeuDarkColors.shadowDark,
        NeuDarkColors.shadowLight,
      ]),
    );
  });

  test('dark tokens match DESIGN.md', () {
    expect(NeuDarkColors.bg, const Color(0xFF292D32));
    expect(NeuDarkColors.shadowLight, const Color(0xFF33383E));
    expect(NeuDarkColors.shadowDark, const Color(0xFF1F2226));
  });
}
