// Persistent app settings: last server address, haptic, theme, deadzone.
// Backed by shared_preferences (PRD F-15 simpan IP, F-18 haptic,
// F-19 deadzone; DESIGN.md 5.2). New dependency rationale: Flutter has
// no built-in key-value persistence; this is the standard plugin.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/packet.dart';

/// Mutable settings with change notifications and async persistence.
class AppSettings extends ChangeNotifier {
  static const String _kIp = 'last_ip';
  static const String _kPort = 'last_port';
  static const String _kHaptic = 'haptic_enabled';
  static const String _kDark = 'dark_mode';
  static const String _kDeadzone = 'deadzone';

  final SharedPreferences _prefs;

  String lastIp;
  int lastPort;
  bool hapticEnabled;
  bool darkMode;
  double deadzone;

  AppSettings({
    required SharedPreferences prefs,
    this.lastIp = '',
    this.lastPort = kDefaultPort,
    this.hapticEnabled = true,
    this.darkMode = false,
    this.deadzone = 0.08,
  }) : _prefs = prefs;

  /// Loads persisted values (or defaults). Injectable prefs for tests.
  static Future<AppSettings> load([SharedPreferences? prefs]) async {
    final SharedPreferences p = prefs ?? await SharedPreferences.getInstance();
    return AppSettings(
      prefs: p,
      lastIp: p.getString(_kIp) ?? '',
      lastPort: p.getInt(_kPort) ?? kDefaultPort,
      hapticEnabled: p.getBool(_kHaptic) ?? true,
      darkMode: p.getBool(_kDark) ?? false,
      deadzone: p.getDouble(_kDeadzone) ?? 0.08,
    );
  }

  Future<void> saveConnection(String ip, int port) async {
    lastIp = ip;
    lastPort = port;
    notifyListeners();
    await _prefs.setString(_kIp, ip);
    await _prefs.setInt(_kPort, port);
  }

  Future<void> setHaptic(bool value) async {
    hapticEnabled = value;
    notifyListeners();
    await _prefs.setBool(_kHaptic, value);
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    notifyListeners();
    await _prefs.setBool(_kDark, value);
  }

  Future<void> setDeadzone(double value) async {
    deadzone = value.clamp(0.0, 0.5);
    notifyListeners();
    await _prefs.setDouble(_kDeadzone, deadzone);
  }
}
