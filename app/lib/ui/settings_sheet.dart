// Settings overlay (DESIGN.md 5.2): haptic toggle, dark mode toggle,
// stick deadzone slider, and disconnect. Reads/writes the persisted
// AppSettings; opened from the controller gear button.

import 'package:flutter/material.dart';

import '../../settings/app_settings.dart';

/// Opens [SettingsSheet] as a modal bottom sheet. [onDisconnect] runs
/// after the sheet closes (e.g. stop sender, pop the controller).
Future<void> showSettingsSheet({
  required BuildContext context,
  required AppSettings settings,
  void Function()? onDisconnect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext sheetContext) => SettingsSheet(
      settings: settings,
      onDisconnect: () {
        Navigator.of(sheetContext).pop();
        onDisconnect?.call();
      },
    ),
  );
}

class SettingsSheet extends StatelessWidget {
  final AppSettings settings;
  final void Function()? onDisconnect;

  const SettingsSheet({
    super.key,
    required this.settings,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, __) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Haptic feedback'),
              subtitle: const Text('Light vibration on button press'),
              value: settings.hapticEnabled,
              onChanged: settings.setHaptic,
            ),
            SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: const Text('Low-light neumorphic theme'),
              value: settings.darkMode,
              onChanged: settings.setDarkMode,
            ),
            ListTile(
              title: const Text('Stick deadzone'),
              subtitle: Slider(
                value: settings.deadzone,
                min: 0,
                max: 0.5,
                divisions: 10,
                label: '${(settings.deadzone * 100).round()}%',
                onChanged: settings.setDeadzone,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDisconnect,
                  child: const Text('Disconnect'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
