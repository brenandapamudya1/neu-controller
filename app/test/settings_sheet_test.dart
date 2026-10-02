// M2c tests: settings sheet toggles persist, disconnect callback.
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/settings/app_settings.dart';
import 'package:padlink/ui/settings_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _loadSettings() async {
  SharedPreferences.setMockInitialValues(const {});
  return AppSettings.load();
}

Future<void> _pumpSheet(
  WidgetTester tester,
  AppSettings settings, {
  void Function()? onDisconnect,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SettingsSheet(
          settings: settings,
          onDisconnect: onDisconnect,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sheet shows all controls', (tester) async {
    await _pumpSheet(tester, await _loadSettings());
    expect(find.byType(SwitchListTile), findsNWidgets(2));
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
  });

  testWidgets('haptic toggle persists', (tester) async {
    final AppSettings settings = await _loadSettings();
    await _pumpSheet(tester, settings);

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(settings.hapticEnabled, isFalse);
  });

  testWidgets('dark mode toggle persists', (tester) async {
    final AppSettings settings = await _loadSettings();
    await _pumpSheet(tester, settings);

    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(settings.darkMode, isTrue);
  });

  testWidgets('deadzone slider changes value', (tester) async {
    final AppSettings settings = await _loadSettings();
    await _pumpSheet(tester, settings);

    await tester.drag(find.byType(Slider), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(settings.deadzone, greaterThan(0.08));
  });

  testWidgets('disconnect button calls back', (tester) async {
    bool called = false;
    await _pumpSheet(
      tester,
      await _loadSettings(),
      onDisconnect: () => called = true,
    );

    await tester.tap(find.text('Disconnect'));
    await tester.pump();
    expect(called, isTrue);
  });
}
