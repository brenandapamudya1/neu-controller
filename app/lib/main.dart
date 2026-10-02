// PadLink entry point: Connect -> Controller (PRD section 6 flow).
// Settings load first so Connect is prefilled with the last address.

import 'package:flutter/material.dart';

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
    return MaterialApp(
      title: 'PadLink',
      home: Builder(
        builder: (BuildContext context) {
          final AppSettings? settings = _settings;
          if (settings == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ConnectScreen(
            settings: settings,
            onConnect: (String host, int port) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ControllerScreen(
                    host: host,
                    port: port,
                    onDisconnect: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
