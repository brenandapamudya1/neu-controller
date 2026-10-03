// Shared pointer-tracking press wrapper for gamepad controls.
// Each control claims exactly one pointer id; other simultaneous pointers
// (other controls, other fingers) are unaffected, so multi-touch works.
// Only down/up transitions rebuild, never pointer moves.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Wraps a control that needs press state. [builder] receives the current
/// pressed flag; [onChanged] fires once per down/up transition.
class NeuPressable extends StatefulWidget {
  final Widget Function(BuildContext context, bool pressed) builder;
  final ValueChanged<bool>? onChanged;

  /// Light haptic on press down. Disabled in widget tests.
  final bool haptic;
  final String? semanticLabel;

  const NeuPressable({
    super.key,
    required this.builder,
    this.onChanged,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<NeuPressable> createState() => _NeuPressableState();
}

class _NeuPressableState extends State<NeuPressable> {
  int? _pointer;
  bool _pressed = false;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return; // already held by another finger
    setState(() {
      _pointer = event.pointer;
      _pressed = true;
    });
    if (widget.haptic) {
      HapticFeedback.lightImpact();
    }
    widget.onChanged?.call(true);
  }

  void _release(int pointer) {
    if (_pointer != pointer) return;
    setState(() {
      _pointer = null;
      _pressed = false;
    });
    widget.onChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = RepaintBoundary(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerUp: (PointerUpEvent event) => _release(event.pointer),
        onPointerCancel: (PointerCancelEvent event) => _release(event.pointer),
        child: widget.builder(context, _pressed),
      ),
    );
    final String? label = widget.semanticLabel;
    if (label != null) {
      child = Semantics(
        button: true,
        label: label,
        child: child,
      );
    }
    return child;
  }
}
