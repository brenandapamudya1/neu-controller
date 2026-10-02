// Full controller screen (M1d): landscape PlayStation-style layout wired
// to a single ControllerState. UdpSender streams it at 60 Hz (M0 path).
// Stick screen-space y maps 1:1 to protocol ly/ry (down positive).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/input_state.dart';
import '../core/theme.dart';
import '../network/packet.dart';
import '../network/udp_sender.dart';
import 'widgets/center_button.dart';
import 'widgets/neu_button.dart';
import 'widgets/neu_dpad.dart';
import 'widgets/neu_joystick.dart';
import 'widgets/shoulder_button.dart';

class ControllerScreen extends StatefulWidget {
  /// Injected for tests; the screen owns and disposes it when absent.
  final ControllerState? controller;

  const ControllerScreen({super.key, this.controller});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  late final ControllerState controller;
  bool _owned = false;
  final TextEditingController ipController =
      TextEditingController(text: '192.168.43.1');
  UdpSender? _sender;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      controller = ControllerState();
      _owned = true;
    } else {
      controller = widget.controller!;
    }
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _sender?.stop();
    ipController.dispose();
    if (_owned) controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (_connected) {
      _sender?.stop();
      _sender = null;
      setState(() => _connected = false);
      return;
    }
    final UdpSender sender = UdpSender(
      state: controller,
      host: ipController.text.trim(),
      port: kDefaultPort,
    );
    await sender.start();
    _sender = sender;
    setState(() => _connected = true);
  }

  void _bindDpad(Set<DpadDirection> dirs) {
    controller.setButton(PadButtons.dpadUp, dirs.contains(DpadDirection.up));
    controller.setButton(
        PadButtons.dpadDown, dirs.contains(DpadDirection.down));
    controller.setButton(
        PadButtons.dpadLeft, dirs.contains(DpadDirection.left));
    controller.setButton(
        PadButtons.dpadRight, dirs.contains(DpadDirection.right));
  }

  int _axis(double v) => (v * 127).round().clamp(-127, 127);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: shoulders outside, center buttons middle.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  ShoulderButton(
                    kind: ShoulderKind.l2,
                    onChanged: (bool p) => controller.setL2(p ? 255 : 0),
                  ),
                  const SizedBox(width: 8),
                  ShoulderButton(
                    kind: ShoulderKind.l1,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.l1, p),
                  ),
                  const Spacer(),
                  CenterButton(
                    label: 'Share',
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.share, p),
                  ),
                  const SizedBox(width: 8),
                  CenterButton(
                    label: 'Home',
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.home, p),
                  ),
                  const SizedBox(width: 8),
                  CenterButton(
                    label: 'Options',
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.options, p),
                  ),
                  const Spacer(),
                  ShoulderButton(
                    kind: ShoulderKind.r1,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.r1, p),
                  ),
                  const SizedBox(width: 8),
                  ShoulderButton(
                    kind: ShoulderKind.r2,
                    onChanged: (bool p) => controller.setR2(p ? 255 : 0),
                  ),
                ],
              ),
            ),
            // Middle: D-pad + left stick | action diamond | right stick.
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        NeuDpad(onChanged: _bindDpad),
                        NeuJoystick(
                          semanticLabel: 'Left stick',
                          onChanged: (Offset o) => controller.setLeftStick(
                            _axis(o.dx),
                            _axis(o.dy),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeuButton.triangle(
                        onChanged: (bool p) =>
                            controller.setButton(PadButtons.triangle, p),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeuButton.square(
                            onChanged: (bool p) => controller.setButton(
                                PadButtons.square, p),
                          ),
                          const SizedBox(
                              width: NeuSizes.actionDefault, height: NeuSizes.actionDefault),
                          NeuButton.circle(
                            onChanged: (bool p) => controller.setButton(
                                PadButtons.circle, p),
                          ),
                        ],
                      ),
                      NeuButton.cross(
                        onChanged: (bool p) =>
                            controller.setButton(PadButtons.cross, p),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: NeuJoystick(
                        semanticLabel: 'Right stick',
                        onChanged: (Offset o) => controller.setRightStick(
                          _axis(o.dx),
                          _axis(o.dy),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom bar: connection status, IP, connect.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _connected ? NeuColors.ok : NeuColors.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _connected ? 'Sending 60 Hz' : 'Not connected',
                    style: const TextStyle(
                      color: NeuColors.textMuted,
                      fontSize: NeuSizes.labelMinFontSize,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: ipController,
                      decoration: const InputDecoration(
                        labelText: 'Laptop IP',
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _toggleConnection,
                    child: Text(_connected ? 'Stop' : 'Connect'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
