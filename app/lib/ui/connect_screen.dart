// Connect screen (DESIGN.md 5.1): neumorphic card with server IP and
// port, Connect button, and hotspot help text. Values persist to
// AppSettings so the next launch is prefilled (PRD F-15).

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../network/packet.dart';
import '../../settings/app_settings.dart';
import 'widgets/neu_surface.dart';

class ConnectScreen extends StatefulWidget {
  final AppSettings settings;
  final void Function(String host, int port) onConnect;

  const ConnectScreen({
    super.key,
    required this.settings,
    required this.onConnect,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.settings.lastIp);
    _portController =
        TextEditingController(text: '${widget.settings.lastPort}');
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() => _error = 'Enter the laptop IP address.');
      return;
    }
    final int? port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) {
      setState(() => _error = 'Port must be a number 1..65535.');
      return;
    }
    setState(() => _error = null);
    await widget.settings.saveConnection(ip, port);
    widget.onConnect(ip, port);
  }

  @override
  Widget build(BuildContext context) {
    final NeuPalette palette = NeuTheme.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: NeuSurface(
            borderRadius: NeuSizes.defaultRadius,
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PadLink',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure the phone and laptop are on the same '
                    'network, or use the phone hotspot.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: NeuSizes.labelMinFontSize,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Laptop IP',
                      hintText: '192.168.43.1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Port',
                      hintText: '$kDefaultPort',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: palette.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Connect'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
