// Full controller screen (M2a): landscape PlayStation-style layout wired
// to a single ControllerState. Opened from ConnectScreen with the saved
// address; auto-connects the 60 Hz UdpSender (PRD section 6 flow).
// Stick screen-space y maps 1:1 to protocol ly/ry (down positive).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  final String host;
  final int port;

  /// False in tests to avoid opening real UDP sockets.
  final bool autoConnect;
  final void Function()? onDisconnect;

  /// From AppSettings (DESIGN.md 5.2). Toggled live via ListenableBuilder.
  final bool haptic;
  final double deadzone;

  const ControllerScreen({
    super.key,
    this.controller,
    this.host = '192.168.43.1',
    this.port = kDefaultPort,
    this.autoConnect = true,
    this.onDisconnect,
    this.haptic = true,
    this.deadzone = 0.08,
  });

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  late final ControllerState controller;
  bool _owned = false;
  UdpSender? _sender;
  bool _connected = false;
  String? _error;

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
    // Keep the screen on during play (PRD F-20). No platform plugin in
    // widget tests, so failures there are ignored.
    _setLocked(true);
    if (widget.autoConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
    }
  }

  @override
  void dispose() {
    _sender?.stop();
    if (_owned) controller.dispose();
    _setLocked(false);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Enables/disables the OS wakelock. Best effort: never crash the UI.
  Future<void> _setLocked(bool locked) async {
    try {
      await WakelockPlus.toggle(enable: locked);
    } catch (_) {
      // Widget tests and unsupported platforms: ignore.
    }
  }

  Future<void> _connect() async {
    try {
      final UdpSender sender = UdpSender(
        state: controller,
        host: widget.host,
        port: widget.port,
      );
      await sender.start();
      _sender = sender;
      if (mounted) {
        setState(() {
          _connected = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not send to ${widget.host}. $e');
      }
    }
  }

  void _disconnect() {
    _sender?.stop();
    _sender = null;
    setState(() => _connected = false);
    widget.onDisconnect?.call();
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
                    haptic: widget.haptic,
                    onChanged: (bool p) => controller.setL2(p ? 255 : 0),
                  ),
                  const SizedBox(width: 8),
                  ShoulderButton(
                    kind: ShoulderKind.l1,
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.l1, p),
                  ),
                  const Spacer(),
                  CenterButton(
                    label: 'Share',
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.share, p),
                  ),
                  const SizedBox(width: 8),
                  CenterButton(
                    label: 'Home',
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.home, p),
                  ),
                  const SizedBox(width: 8),
                  CenterButton(
                    label: 'Options',
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.options, p),
                  ),
                  const Spacer(),
                  ShoulderButton(
                    kind: ShoulderKind.r1,
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.r1, p),
                  ),
                  const SizedBox(width: 8),
                  ShoulderButton(
                    kind: ShoulderKind.r2,
                    haptic: widget.haptic,
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
                        NeuDpad(
                          onChanged: _bindDpad,
                          haptic: widget.haptic,
                        ),
                        NeuJoystick(
                          semanticLabel: 'Left stick',
                          haptic: widget.haptic,
                          deadzone: widget.deadzone,
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
                        haptic: widget.haptic,
                        onChanged: (bool p) =>
                            controller.setButton(PadButtons.triangle, p),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeuButton.square(
                            haptic: widget.haptic,
                            onChanged: (bool p) => controller.setButton(
                                PadButtons.square, p),
                          ),
                          const SizedBox(
                              width: NeuSizes.actionDefault,
                              height: NeuSizes.actionDefault),
                          NeuButton.circle(
                            haptic: widget.haptic,
                            onChanged: (bool p) => controller.setButton(
                                PadButtons.circle, p),
                          ),
                        ],
                      ),
                      NeuButton.cross(
                        haptic: widget.haptic,
                        onChanged: (bool p) =>
                            controller.setButton(PadButtons.cross, p),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: NeuJoystick(
                        semanticLabel: 'Right stick',
                        haptic: widget.haptic,
                        deadzone: widget.deadzone,
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
            // Bottom bar: connection status and disconnect.
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
                  Expanded(
                    child: Text(
                      _error ??
                          (_connected
                              ? 'Sending 60 Hz to ${widget.host}:${widget.port}'
                              : 'Connecting to ${widget.host}:${widget.port}...'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NeuColors.textMuted,
                        fontSize: NeuSizes.labelMinFontSize,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _disconnect,
                    child:
                        Text(_connected || _error != null ? 'Disconnect' : 'Back'),
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
