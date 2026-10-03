// M2a+M3b tests: Connect validation, prefill, persist, callback, scan.
// Run with: flutter test (requires Flutter SDK).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
  List<String> connected, {
  Duration scanDuration = const Duration(milliseconds: 200),
  String discoveryTarget = '127.0.0.1',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ConnectScreen(
        settings: settings,
        onConnect: (String host, int port) =>
            connected.add('$host:$port'),
        scanDuration: scanDuration,
        discoveryTarget: discoveryTarget,
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

  testWidgets('empty scan shows rescan hint', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final AppSettings settings = await AppSettings.load();
    await _pumpConnect(tester, settings, <String>[]);

    // No responder on loopback: scan times out with guidance.
    expect(find.textContaining('No servers found'), findsOneWidget);
    expect(find.text('Rescan'), findsOneWidget);
  });

  testWidgets('discovered server fills the fields on tap', (tester) async {
    // Fake server answering discovery on loopback. Socket setup and the
    // real-time wait run in the real async zone (runAsync), because
    // widget tests otherwise fake the clock.
    late RawDatagramSocket responder;
    late StreamSubscription<void> sub;
    await tester.runAsync(() async {
      responder =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      sub = responder.listen((RawSocketEvent e) {
        if (e != RawSocketEvent.read) return;
        final Datagram? dg = responder.receive();
        if (dg == null || dg.data.length != 5) return;
        final List<int> nameBytes = utf8.encode('testbox');
        final Uint8List reply = Uint8List(7 + nameBytes.length)
          ..setRange(0, 4, <int>[0x50, 0x4C, 0x64, 0x73])
          ..[4] = 0x01
          ..[5] = responder.port & 0xFF
          ..[6] = (responder.port >> 8) & 0xFF
          ..setRange(7, 7 + nameBytes.length, nameBytes);
        responder.send(reply, dg.address, dg.port);
      });
    });
    final int responderPort = responder.port;

    SharedPreferences.setMockInitialValues(
        <String, Object>{'last_port': responderPort});
    final AppSettings settings = await AppSettings.load();
    final List<String> connected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ConnectScreen(
          settings: settings,
          onConnect: (String host, int port) =>
              connected.add('$host:$port'),
          scanDuration: const Duration(milliseconds: 300),
          discoveryTarget: '127.0.0.1',
        ),
      ),
    );
    // Let the real socket round-trip happen, then settle fake timers.
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 700),
        ));
    await tester.pumpAndSettle();

    expect(find.text('testbox'), findsOneWidget);
    await tester.tap(find.text('testbox'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
      '127.0.0.1',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
      '$responderPort',
    );

    await tester.runAsync(() async {
      await sub.cancel();
      responder.close();
    });
  });
}
