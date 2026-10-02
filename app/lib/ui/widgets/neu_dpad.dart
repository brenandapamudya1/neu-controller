// Plus-shaped D-pad: one sliding pointer, diagonals light two segments.
// Reports the active direction set; the screen maps it to button bits.
// Segment visuals only — a single Listener owns the whole 150 dp area.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme.dart';
import 'action_glyph.dart';
import 'neu_surface.dart';

/// D-pad direction, one per arm of the plus.
enum DpadDirection {
  up,
  down,
  left,
  right,
}

/// 150 dp plus D-pad. A single finger may slide between arms;
/// corners activate diagonals (two directions at once).
class NeuDpad extends StatefulWidget {
  final ValueChanged<Set<DpadDirection>>? onChanged;

  /// Light haptic on first press. Disabled in widget tests.
  final bool haptic;

  const NeuDpad({
    super.key,
    this.onChanged,
    this.haptic = true,
  });

  @override
  State<NeuDpad> createState() => _NeuDpadState();
}

class _NeuDpadState extends State<NeuDpad> {
  int? _pointer;
  Set<DpadDirection> _dirs = const {};

  void _resolve(Offset local) {
    final double dx = (local.dx - _half) / _half;
    final double dy = (local.dy - _half) / _half;
    if (dx * dx + dy * dy < _dead * _dead) {
      _emit(const {});
      return;
    }
    final Set<DpadDirection> next = {};
    if (dx > _axisThreshold) next.add(DpadDirection.right);
    if (dx < -_axisThreshold) next.add(DpadDirection.left);
    if (dy > _axisThreshold) next.add(DpadDirection.down);
    if (dy < -_axisThreshold) next.add(DpadDirection.up);
    _emit(next);
  }

  void _emit(Set<DpadDirection> next) {
    if (_same(next, _dirs)) return;
    final bool wasIdle = _dirs.isEmpty;
    setState(() => _dirs = next);
    if (wasIdle && next.isNotEmpty && widget.haptic) {
      HapticFeedback.lightImpact();
    }
    widget.onChanged?.call(next);
  }

  bool _same(Set<DpadDirection> a, Set<DpadDirection> b) {
    return a.length == b.length && a.containsAll(b);
  }

  void _down(PointerDownEvent event) {
    if (_pointer != null) return; // one sliding finger per D-pad
    _pointer = event.pointer;
    _resolve(event.localPosition);
  }

  void _move(PointerMoveEvent event) {
    if (_pointer != event.pointer) return;
    _resolve(event.localPosition);
  }

  void _release(int pointer) {
    if (_pointer != pointer) return;
    _pointer = null;
    _emit(const {});
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'D-pad',
      child: RepaintBoundary(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: (PointerUpEvent event) => _release(event.pointer),
          onPointerCancel: (PointerCancelEvent event) =>
              _release(event.pointer),
          child: SizedBox.square(
            dimension: NeuSizes.dpadTotal,
            // Fixed 3x3 grid (no scrolling): arms, concave hub, dead corners.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(dimension: _cell),
                    _Segment(
                      active: _dirs.contains(DpadDirection.up),
                      quarterTurns: 0,
                    ),
                    const SizedBox.square(dimension: _cell),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Segment(
                      active: _dirs.contains(DpadDirection.left),
                      quarterTurns: 3,
                    ),
                    // Center hub: concave, never active.
                    const NeuSurface.circle(
                      diameter: _cell,
                      pressed: true,
                    ),
                    _Segment(
                      active: _dirs.contains(DpadDirection.right),
                      quarterTurns: 1,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(dimension: _cell),
                    _Segment(
                      active: _dirs.contains(DpadDirection.down),
                      quarterTurns: 2,
                    ),
                    const SizedBox.square(dimension: _cell),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Total D-pad span (DESIGN.md) and derived cell size.
const double _half = NeuSizes.dpadTotal / 2;
const double _cell = NeuSizes.dpadTotal / 3;

/// Center dead radius in unit space; axis activation threshold.
const double _dead = 0.25;
const double _axisThreshold = 0.3;

/// One arm of the plus. Visual only; the parent Listener owns input.
class _Segment extends StatelessWidget {
  final bool active;

  /// Rotates the up-pointing triangle glyph toward the arm direction.
  final int quarterTurns;

  const _Segment({
    required this.active,
    required this.quarterTurns,
  });

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      width: _cell,
      height: _cell,
      pressed: active,
      small: true,
      borderRadius: _segmentRadius,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: ActionGlyph(
          kind: ActionGlyphKind.triangle,
          color: active ? NeuColors.accent : NeuColors.textMuted,
          size: _arrowSize,
        ),
      ),
    );
  }
}

/// Slightly rounded plus arms and compact arrows.
const double _segmentRadius = 12;
const double _arrowSize = 22;
