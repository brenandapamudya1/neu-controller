// Connect screen (DESIGN.md 5.1): neumorphic card with server IP and
// port, Connect button, hotspot help text, and LAN auto-discovery.
// Values persist to AppSettings so the next launch is prefilled (PRD F-15).

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../network/discovery.dart';
import '../../network/packet.dart';
import '../../settings/app_settings.dart';
import 'widgets/neu_surface.dart';

class ConnectScreen extends StatefulWidget {
  final AppSettings settings;
  final void Function(String host, int port) onConnect;

  /// Shortened in tests so scans finish fast.
  final Duration scanDuration;

  /// Overridden in tests to point the query at loopback.
  final String discoveryTarget;

  const ConnectScreen({
    super.key,
    required this.settings,
    required this.onConnect,
    this.scanDuration = const Duration(seconds: 3),
    this.discoveryTarget = '255.255.255.255',
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  DiscoveryService? _discovery;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.settings.lastIp);
    _portController =
        TextEditingController(text: '${widget.settings.lastPort}');
    // Scan once on open so nearby servers appear without tapping.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _discovery?.dispose();
    _discovery = null;
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    _discovery?.dispose();
    final DiscoveryService discovery = DiscoveryService(
      port: int.tryParse(_portController.text.trim()) ?? kDefaultPort,
      scanDuration: widget.scanDuration,
    );
    _discovery = discovery;
    try {
      await discovery.scan(target: widget.discoveryTarget);
    } catch (_) {
      // No broadcast capability (e.g. some test envs): manual IP remains.
    }
    if (mounted) setState(() {});
  }

  void _pickServer(DiscoveredServer server) {
    setState(() {
      _ipController.text = server.ip;
      _portController.text = '${server.port}';
      _error = null;
    });
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
                    decoration: const InputDecoration(
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
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Nearby servers',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: NeuSizes.labelMinFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _ScanButton(
                        discovery: _discovery,
                        onPressed: _startScan,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ServerList(
                    discovery: _discovery,
                    palette: palette,
                    onPick: _pickServer,
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

/// Scan button showing a spinner while the LAN scan runs.
class _ScanButton extends StatelessWidget {
  final DiscoveryService? discovery;
  final void Function() onPressed;

  const _ScanButton({required this.discovery, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final DiscoveryService? service = discovery;
    if (service == null) {
      return TextButton(onPressed: onPressed, child: const Text('Scan'));
    }
    return ValueListenableBuilder<bool>(
      valueListenable: service.scanning,
      builder: (_, bool scanning, __) {
        if (scanning) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        return TextButton(onPressed: onPressed, child: const Text('Rescan'));
      },
    );
  }
}

/// List of discovered servers; tapping one fills the IP/port fields.
class _ServerList extends StatelessWidget {
  final DiscoveryService? discovery;
  final NeuPalette palette;
  final void Function(DiscoveredServer server) onPick;

  const _ServerList({
    required this.discovery,
    required this.palette,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final DiscoveryService? service = discovery;
    if (service == null) {
      return Text(
        'Scanning for servers...',
        style: TextStyle(
          color: palette.textMuted,
          fontSize: NeuSizes.labelMinFontSize,
        ),
      );
    }
    return ValueListenableBuilder<List<DiscoveredServer>>(
      valueListenable: service.servers,
      builder: (_, List<DiscoveredServer> servers, __) {
        if (servers.isEmpty) {
          return ValueListenableBuilder<bool>(
            valueListenable: service.scanning,
            builder: (_, bool scanning, __) => Text(
              scanning
                  ? 'Scanning for servers...'
                  : 'No servers found. Check the hotspot and rescan.',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: NeuSizes.labelMinFontSize,
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final DiscoveredServer server in servers)
              // Transparent Material so ListTile ink has a canvas that
              // the neumorphic DecoratedBox above does not provide.
              Material(
                color: Colors.transparent,
                borderRadius:
                    BorderRadius.circular(NeuSizes.defaultRadius),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(server.name.isEmpty ? server.ip : server.name),
                  subtitle: Text('${server.ip}:${server.port}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onPick(server),
                ),
              ),
          ],
        );
      },
    );
  }
}
