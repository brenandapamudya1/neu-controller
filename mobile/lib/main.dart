// PadLink entry point: Connect -> Controller (PRD section 6 flow).
// Settings load first so Connect is prefilled; the active NeuTheme
// (light/dark) sits above everything and rebuilds on setting changes.

import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'settings/app_settings.dart';
import 'ui/connect_screen.dart';
import 'ui/controller_screen.dart';

void main() {
  runApp(const PadLinkApp());
}

class PadLinkApp extends StatefulWidget {
  const PadLinkApp({super.key});

  @override
  State<PadLinkApp> createState() => _PadLinkAppState();
}

class _PadLinkAppState extends State<PadLinkApp> {
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    AppSettings.load().then((AppSettings s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  @override
  void dispose() {
    _settings?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings? settings = _settings;
    if (settings == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return ListenableBuilder(
      listenable: settings,
      builder: (_, __) => NeuTheme(
        palette: settings.darkMode ? NeuPalette.dark : NeuPalette.light,
        child: MaterialApp(
          title: 'PadLink',
          theme: settings.darkMode ? ThemeData.dark() : ThemeData.light(),
          home: Builder(
            builder: (BuildContext context) {
              return ConnectScreen(
                settings: settings,
                onConnect: (String host, int port) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ControllerScreen(
                        host: host,
                        port: port,
                        haptic: settings.hapticEnabled,
                        deadzone: settings.deadzone,
                        settings: settings,
                        onDisconnect: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
