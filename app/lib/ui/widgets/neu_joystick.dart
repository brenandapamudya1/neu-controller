// Analog joystick: concave base + protruding knob, fixed origin.
// Knob follows the finger clamped to the travel radius and snaps back to
// center in 120 ms (easeOutBack) on release. Reports Offset(-1..1) in
// screen space (y down); mapping to lx/ly happens in the controller
// screen. Deadzone 8% per DESIGN.md. One pointer at a time per stick.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme.dart';
import 'neu_surface.dart';

class NeuJoystick extends StatefulWidget {
  final double baseDiameter;
  final double knobDiameter;

  /// Deflections below this magnitude report as zero. 0..1.
  final double deadzone;
  final ValueChanged<Offset>? onChanged;

  /// Light haptic on press down. Disabled in widget tests.
  final bool haptic;
  final String semanticLabel;

  const NeuJoystick({
    super.key,
    this.baseDiameter = NeuSizes.stickBaseDefault,
    this.knobDiameter = NeuSizes.stickKnobDefault,
    this.deadzone = 0.08,
    this.onChanged,
    this.haptic = true,
    this.semanticLabel = 'Joystick',
  })  : assert(deadzone >= 0 && deadzone < 1),
        assert(baseDiameter > knobDiameter);

  @override
  State<NeuJoystick> createState() => _NeuJoystickState();
}

class _NeuJoystickState extends State<NeuJoystick>
    with SingleTickerProviderStateMixin {
  int? _pointer;

  /// Knob offset in pixels from center, already clamped to [_travel].
  Offset _knob = Offset.zero;

  late final AnimationController _returnController;
  Animation<Offset>? _returnAnim;

  /// Maximum knob travel in pixels: ring between base edge and knob edge.
  double get _travel => (widget.baseDiameter - widget.knobDiameter) / 2;

  @override
  void initState() {
    super.initState();
    _returnController = AnimationController(
      duration: NeuMotion.knobReturn,
      vsync: this,
    )..addListener(_onReturnTick);
  }

  void _onReturnTick() {
    final Animation<Offset>? anim = _returnAnim;
    if (anim == null) return;
    setState(() => _knob = anim.value);
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }

  /// Pixels-to-unit mapping with deadzone and unit-circle clamp.
  Offset _normalized(Offset pixels) {
    final Offset unit = pixels / _travel;
    if (unit.distance < widget.deadzone) return Offset.zero;
    if (unit.distance > 1) return unit / unit.distance;
    return unit;
  }

  void _trackKnob(Offset globalPosition) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset local = box.globalToLocal(globalPosition);
    final Offset center =
        Offset(widget.baseDiameter, widget.baseDiameter) / 2;
    Offset delta = local - center;
    if (delta.distance > _travel) {
      delta = delta / delta.distance * _travel;
    }
    setState(() => _knob = delta);
    widget.onChanged?.call(_normalized(delta));
  }

  void _down(PointerDownEvent event) {
    if (_pointer != null) return; // already held by another finger
    _returnController.stop();
    _returnAnim = null;
    _pointer = event.pointer;
    if (widget.haptic) {
      HapticFeedback.lightImpact();
    }
    _trackKnob(event.position);
  }

  void _move(PointerMoveEvent event) {
    if (_pointer != event.pointer) return;
    _trackKnob(event.position);
  }

  void _release(int pointer) {
    if (_pointer != pointer) return;
    _pointer = null;
    // Neutral immediately so the network state recenters at once;
    // the knob visual catches up over 120 ms.
    widget.onChanged?.call(Offset.zero);
    _returnAnim = Tween<Offset>(begin: _knob, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _returnController,
        curve: NeuMotion.knobReturnCurve,
      ),
    );
    _returnController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _pointer != null;
    final NeuPalette palette = NeuTheme.of(context);
    final double rest = (widget.baseDiameter - widget.knobDiameter) / 2;
    return Semantics(
      label: widget.semanticLabel,
      child: RepaintBoundary(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: (PointerUpEvent event) => _release(event.pointer),
          onPointerCancel: (PointerCancelEvent event) =>
              _release(event.pointer),
          child: SizedBox.square(
            dimension: widget.baseDiameter,
            child: Stack(
              children: [
                NeuSurface.circle(
                  diameter: widget.baseDiameter,
                  pressed: true,
                ),
                Positioned(
                  key: const Key('neu-knob'),
                  left: rest + _knob.dx,
                  top: rest + _knob.dy,
                  child: NeuSurface.circle(
                    diameter: widget.knobDiameter,
                    small: true,
                    child: AnimatedContainer(
                      duration: NeuMotion.press,
                      width: widget.knobDiameter * _dotRatio,
                      height: widget.knobDiameter * _dotRatio,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? palette.accent
                            : palette.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Center dot occupies ~28% of the knob diameter.
const double _dotRatio = 0.28;
