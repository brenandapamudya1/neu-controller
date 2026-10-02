// M2a tests: Connect validation, prefill, persist, callback.
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/settings/app_settings.dart';
import 'package:padlink/ui/connect_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _loadSettings() async {
  SharedPreferences.setMockInitialValues(const {
    'last_ip': '10.0.0.2',
    'last_port': 1234,
  });
  return AppSettings.load();
}

Future<void> _pumpConnect(
  WidgetTester tester,
  AppSettings settings,
  List<String> connected,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ConnectScreen(
        settings: settings,
        onConnect: (String host, int port) =>
            connected.add('$host:$port'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fields prefilled from saved settings', (tester) async {
    final AppSettings settings = await _loadSettings();
    await _pumpConnect(tester, settings, <String>[]);

    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
      '10.0.0.2',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
      '1234',
    );
  });

  testWidgets('empty IP shows error and does not connect', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final AppSettings settings = await AppSettings.load();
    final List<String> connected = <String>[];
    await _pumpConnect(tester, settings, connected);

    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(find.text('Enter the laptop IP address.'), findsOneWidget);
    expect(connected, isEmpty);
  });

  testWidgets('bad port shows error and does not connect', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final AppSettings settings = await AppSettings.load();
    final List<String> connected = <String>[];
    await _pumpConnect(tester, settings, connected);

    await tester.enterText(find.byType(TextField).at(0), '192.168.1.9');
    await tester.enterText(find.byType(TextField).at(1), 'abc');
    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(find.text('Port must be a number 1..65535.'), findsOneWidget);
    expect(connected, isEmpty);
  });

  testWidgets('valid submit persists and calls onConnect', (tester) async {
    final AppSettings settings = await _loadSettings();
    final List<String> connected = <String>[];
    await _pumpConnect(tester, settings, connected);

    await tester.enterText(find.byType(TextField).at(0), '192.168.1.9');
    await tester.enterText(find.byType(TextField).at(1), '9876');
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(connected, <String>['192.168.1.9:9876']);
    expect(settings.lastIp, '192.168.1.9');
    expect(settings.lastPort, 9876);
  });
}
