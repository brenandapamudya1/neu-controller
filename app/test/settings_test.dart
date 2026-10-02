// Settings persistence tests (mock SharedPreferences, no device).
// Run with: flutter test (requires Flutter SDK).

import 'package:flutter_test/flutter_test.dart';
import 'package:padlink/network/packet.dart';
import 'package:padlink/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults when nothing persisted', () async {
    SharedPreferences.setMockInitialValues(const {});
    final AppSettings settings = await AppSettings.load();
    expect(settings.lastIp, '');
    expect(settings.lastPort, kDefaultPort);
    expect(settings.hapticEnabled, isTrue);
    expect(settings.darkMode, isFalse);
    expect(settings.deadzone, 0.08);
  });

  test('save/load round-trips connection and toggles', () async {
    SharedPreferences.setMockInitialValues(const {});
    final AppSettings settings = await AppSettings.load();

    await settings.saveConnection('192.168.1.5', 9999);
    await settings.setHaptic(false);
    await settings.setDarkMode(true);
    await settings.setDeadzone(0.15);

    // Reload from the same mock store.
    final AppSettings reloaded = await AppSettings.load();
    expect(reloaded.lastIp, '192.168.1.5');
    expect(reloaded.lastPort, 9999);
    expect(reloaded.hapticEnabled, isFalse);
    expect(reloaded.darkMode, isTrue);
    expect(reloaded.deadzone, 0.15);
  });

  test('deadzone clamps to 0..0.5', () async {
    SharedPreferences.setMockInitialValues(const {});
    final AppSettings settings = await AppSettings.load();

    await settings.setDeadzone(0.9);
    expect(settings.deadzone, 0.5);
    await settings.setDeadzone(-0.1);
    expect(settings.deadzone, 0.0);
  });
}
