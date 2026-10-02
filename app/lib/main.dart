// PadLink entry point: landscape controller wired to UDP (see
// ui/controller_screen.dart). Orientation lock lives in the screen.

import 'package:flutter/material.dart';

import 'ui/controller_screen.dart';

void main() {
  runApp(const PadLinkApp());
}

class PadLinkApp extends StatelessWidget {
  const PadLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PadLink',
      home: ControllerScreen(),
    );
  }
}
