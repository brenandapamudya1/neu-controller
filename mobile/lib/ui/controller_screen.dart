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
import '../network/ping_service.dart';
import '../network/udp_sender.dart';
import '../settings/app_settings.dart';
import 'settings_sheet.dart';
import 'widgets/center_button.dart';
import 'widgets/neu_button.dart';
import 'widgets/neu_dpad.dart';
import 'widgets/neu_joystick.dart';
import 'widgets/neu_pressable.dart';
import 'widgets/neu_surface.dart';
import 'widgets/shoulder_button.dart';
import 'widgets/status_pill.dart';

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

  /// Enables the gear button opening the settings sheet. Hidden in
  /// goldens/tests that do not pass settings.
  final AppSettings? settings;

  const ControllerScreen({
    super.key,
    this.controller,
    this.host = '192.168.43.1',
    this.port = kDefaultPort,
    this.autoConnect = true,
    this.onDisconnect,
    this.haptic = true,
    this.deadzone = 0.08,
    this.settings,
  });

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  late final ControllerState controller;
  bool _owned = false;
  UdpSender? _sender;
  PingService? _ping;
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
    _ping?.dispose();
    _ping = null;
    if (_owned) controller.dispose();
    _setLocked(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      final PingService ping = PingService(
        host: widget.host,
        port: widget.port,
      );
      await ping.start();
      _sender = sender;
      _ping = ping;
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
    _ping?.dispose();
    _ping = null;
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
    final NeuPalette palette = NeuTheme.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Left shoulders (L1, L2, L3), Center Lightbar, Right shoulders (R3, R2, R1).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  ShoulderButton(
                    kind: ShoulderKind.l1,
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.l1, p),
                  ),
                  const SizedBox(width: 6),
                  ShoulderButton(
                    kind: ShoulderKind.l2,
                    haptic: widget.haptic,
                    onChanged: (bool p) => controller.setL2(p ? 255 : 0),
                  ),
                  const SizedBox(width: 6),
                  ShoulderButton(
                    kind: ShoulderKind.l3,
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.l3, p),
                  ),
                  const Spacer(),
                  // Subtle PlayStation DualSense style lightbar
                  Container(
                    width: 72,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _connected
                          ? palette.ok
                          : palette.accent.withAlpha(140),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: (_connected ? palette.ok : palette.accent)
                              .withAlpha(90),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ShoulderButton(
                    kind: ShoulderKind.r3,
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.r3, p),
                  ),
                  const SizedBox(width: 6),
                  ShoulderButton(
                    kind: ShoulderKind.r2,
                    haptic: widget.haptic,
                    onChanged: (bool p) => controller.setR2(p ? 255 : 0),
                  ),
                  const SizedBox(width: 6),
                  ShoulderButton(
                    kind: ShoulderKind.r1,
                    haptic: widget.haptic,
                    onChanged: (bool p) =>
                        controller.setButton(PadButtons.r1, p),
                  ),
                ],
              ),
            ),
            // Middle: PlayStation DualShock layout.
            // Left wing: D-Pad (upper-left) + Left Stick (lower-right, inward).
            // Center: Touchpad + Share/Options + Home (PS) button.
            // Right wing: Right Stick (lower-left, inward) + Action Diamond (upper-right).
            Expanded(
              child: Row(
                children: [
                  // Left Wing (Grip Pod)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 2, 4, 4),
                      decoration: BoxDecoration(
                        color: palette.bg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: NeuShadows.raisedSmall(
                          dark: palette.shadowDark,
                          light: palette.shadowLight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Align(
                              alignment: const Alignment(0, -0.35),
                              child: NeuDpad(
                                onChanged: _bindDpad,
                                haptic: widget.haptic,
                              ),
                            ),
                            Align(
                              alignment: const Alignment(0, 0.4),
                              child: NeuJoystick(
                                semanticLabel: 'Left stick',
                                baseDiameter: 130,
                                knobDiameter: 54,
                                haptic: widget.haptic,
                                deadzone: widget.deadzone,
                                onChanged: (Offset o) => controller.setLeftStick(
                                  _axis(o.dx),
                                  _axis(o.dy),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Center Console: PlayStation Touchpad, Share, Options, Home (PS)
                  SizedBox(
                    width: 114,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CenterButton(
                              label: 'Share',
                              haptic: widget.haptic,
                              onChanged: (bool p) =>
                                  controller.setButton(PadButtons.share, p),
                            ),
                            const SizedBox(width: 6),
                            CenterButton(
                              label: 'Options',
                              haptic: widget.haptic,
                              onChanged: (bool p) =>
                                  controller.setButton(PadButtons.options, p),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        NeuSurface(
                          width: 104,
                          height: 56,
                          pressed: true,
                          borderRadius: 12,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: palette.textMuted.withAlpha(70),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'TOUCHPAD',
                                  style: TextStyle(
                                    color: palette.textMuted.withAlpha(110),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        CenterButton(
                          label: 'Home',
                          haptic: widget.haptic,
                          onChanged: (bool p) =>
                              controller.setButton(PadButtons.home, p),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  // Right Wing (Grip Pod)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(4, 2, 8, 4),
                      decoration: BoxDecoration(
                        color: palette.bg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: NeuShadows.raisedSmall(
                          dark: palette.shadowDark,
                          light: palette.shadowLight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Align(
                              alignment: const Alignment(0, 0.4),
                              child: NeuJoystick(
                                semanticLabel: 'Right stick',
                                baseDiameter: 130,
                                knobDiameter: 54,
                                haptic: widget.haptic,
                                deadzone: widget.deadzone,
                                onChanged: (Offset o) =>
                                    controller.setRightStick(
                                  _axis(o.dx),
                                  _axis(o.dy),
                                ),
                              ),
                            ),
                            Align(
                              alignment: const Alignment(0, -0.35),
                              child: _ActionDiamond(
                                haptic: widget.haptic,
                                controller: controller,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom bar: latency pill, address/error, neumorphic disconnect & settings.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  if (_ping != null)
                    ValueListenableBuilder<int?>(
                      valueListenable: _ping!.rttMs,
                      builder: (_, int? rtt, __) => StatusPill(rttMs: rtt),
                    )
                  else
                    const StatusPill(rttMs: null),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error ?? '${widget.host}:${widget.port}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: NeuSizes.labelMinFontSize,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  NeuPressable(
                    onChanged: (bool p) {
                      if (!p) _disconnect();
                    },
                    haptic: widget.haptic,
                    semanticLabel:
                        _connected || _error != null ? 'Disconnect' : 'Back',
                    builder: (BuildContext context, bool pressed) {
                      return NeuSurface(
                        pressed: pressed,
                        small: true,
                        borderRadius: NeuSizes.pillRadius,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          _connected || _error != null ? 'Disconnect' : 'Back',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: NeuSizes.labelMinFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  if (widget.settings != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: NeuPressable(
                        onChanged: (bool p) {
                          if (!p) {
                            showSettingsSheet(
                              context: context,
                              settings: widget.settings!,
                              onDisconnect: _disconnect,
                            );
                          }
                        },
                        haptic: widget.haptic,
                        semanticLabel: 'Settings',
                        builder: (BuildContext context, bool pressed) {
                          return NeuSurface.circle(
                            diameter: 36,
                            pressed: pressed,
                            small: true,
                            child: Icon(
                              Icons.settings,
                              size: 18,
                              color: palette.textMuted,
                            ),
                          );
                        },
                      ),
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

/// PlayStation action button diamond: Triangle (top), Square (left),
/// Circle (right), Cross (bottom), centered in a 150 dp square matching NeuDpad.
class _ActionDiamond extends StatelessWidget {
  final bool haptic;
  final ControllerState controller;

  const _ActionDiamond({
    required this.haptic,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    const double size = NeuSizes.dpadTotal; // 150 dp
    const double btnSize = 54;
    const double offset = (size - btnSize) / 2; // 48 dp

    return Semantics(
      label: 'Action buttons',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            // Triangle (top)
            Positioned(
              top: 0,
              left: offset,
              child: NeuButton.triangle(
                diameter: btnSize,
                haptic: haptic,
                onChanged: (bool p) =>
                    controller.setButton(PadButtons.triangle, p),
              ),
            ),
            // Square (left)
            Positioned(
              top: offset,
              left: 0,
              child: NeuButton.square(
                diameter: btnSize,
                haptic: haptic,
                onChanged: (bool p) =>
                    controller.setButton(PadButtons.square, p),
              ),
            ),
            // Circle (right)
            Positioned(
              top: offset,
              right: 0,
              child: NeuButton.circle(
                diameter: btnSize,
                haptic: haptic,
                onChanged: (bool p) =>
                    controller.setButton(PadButtons.circle, p),
              ),
            ),
            // Cross (bottom)
            Positioned(
              bottom: 0,
              left: offset,
              child: NeuButton.cross(
                diameter: btnSize,
                haptic: haptic,
                onChanged: (bool p) =>
                    controller.setButton(PadButtons.cross, p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
