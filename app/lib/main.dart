// M0 minimal: IP connect + one button (Cross) -> UDP -> virtual gamepad.
// Uses Listener (pointer events) so multi-touch stays correct later.

import 'package:flutter/material.dart';

import 'core/input_state.dart';
import 'network/packet.dart';
import 'network/udp_sender.dart';

void main() {
  runApp(const PadLinkApp());
}

class PadLinkApp extends StatelessWidget {
  const PadLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PadLink M0',
      home: const M0ControllerPage(),
    );
  }
}

class M0ControllerPage extends StatefulWidget {
  const M0ControllerPage({super.key});

  @override
  State<M0ControllerPage> createState() => _M0ControllerPageState();
}

class _M0ControllerPageState extends State<M0ControllerPage> {
  final ControllerState controller = ControllerState();
  final TextEditingController ipController =
      TextEditingController(text: '192.168.43.1');
  UdpSender? sender;
  bool connected = false;
  bool pressed = false;

  @override
  void dispose() {
    sender?.stop();
    controller.dispose();
    ipController.dispose();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (connected) {
      sender?.stop();
      sender = null;
      setState(() => connected = false);
      return;
    }
    final s = UdpSender(
      state: controller,
      host: ipController.text.trim(),
      port: kDefaultPort,
    );
    await s.start();
    sender = s;
    setState(() => connected = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PadLink M0')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ipController,
                    decoration: const InputDecoration(
                      labelText: 'Laptop IP (port 9876)',
                      hintText: '192.168.43.1',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _toggleConnection,
                  child: Text(connected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              connected ? 'Sending 60 Hz...' : 'Not connected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            // Single M0 button. Listener tracks pointer down/up/cancel.
            Listener(
              onPointerDown: (_) {
                controller.setButton(PadButtons.cross, true);
                setState(() => pressed = true);
              },
              onPointerUp: (_) {
                controller.setButton(PadButtons.cross, false);
                setState(() => pressed = false);
              },
              onPointerCancel: (_) {
                controller.setButton(PadButtons.cross, false);
                setState(() => pressed = false);
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pressed ? Colors.blue.shade200 : Colors.grey.shade300,
                  border: Border.all(color: Colors.grey),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'X',
                  style: TextStyle(fontSize: 64),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Hotspot HP -> laptop join -> isi IP laptop -> Connect -> tahan X, cek evtest.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
