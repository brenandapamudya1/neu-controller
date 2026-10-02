// Round neumorphic action button with a vector glyph.
// Reports press via onChanged; callers map it to ControllerState bits.
// Never sends networking itself.

import 'package:flutter/widgets.dart';

import '../../core/theme.dart';
import 'action_glyph.dart';
import 'neu_pressable.dart';
import 'neu_surface.dart';

/// Circular gamepad action button (triangle, circle, cross, square).
class NeuButton extends StatelessWidget {
  final ActionGlyphKind glyph;
  final Color glyphColor;
  final double diameter;
  final ValueChanged<bool>? onChanged;
  final bool haptic;
  final String? semanticLabel;

  const NeuButton({
    super.key,
    required this.glyph,
    required this.glyphColor,
    this.diameter = NeuSizes.actionDefault,
    this.onChanged,
    this.haptic = true,
    this.semanticLabel,
  });

  /// Cross (X): bottom of the diamond, blue.
  const NeuButton.cross({
    super.key,
    this.diameter = NeuSizes.actionDefault,
    this.onChanged,
    this.haptic = true,
    this.semanticLabel = 'Cross',
  })  : glyph = ActionGlyphKind.cross,
        glyphColor = NeuColors.cross;

  /// Circle: right of the diamond, red.
  const NeuButton.circle({
    super.key,
    this.diameter = NeuSizes.actionDefault,
    this.onChanged,
    this.haptic = true,
    this.semanticLabel = 'Circle',
  })  : glyph = ActionGlyphKind.circle,
        glyphColor = NeuColors.circle;

  /// Square: left of the diamond, pink.
  const NeuButton.square({
    super.key,
    this.diameter = NeuSizes.actionDefault,
    this.onChanged,
    this.haptic = true,
    this.semanticLabel = 'Square',
  })  : glyph = ActionGlyphKind.square,
        glyphColor = NeuColors.square;

  /// Triangle: top of the diamond, green.
  const NeuButton.triangle({
    super.key,
    this.diameter = NeuSizes.actionDefault,
    this.onChanged,
    this.haptic = true,
    this.semanticLabel = 'Triangle',
  })  : glyph = ActionGlyphKind.triangle,
        glyphColor = NeuColors.triangle;

  @override
  Widget build(BuildContext context) {
    return NeuPressable(
      onChanged: onChanged,
      haptic: haptic,
      semanticLabel: semanticLabel,
      builder: (BuildContext context, bool pressed) {
        // Pressed glyph darkens so the state is obvious even on
        // low-contrast neumorphism (DESIGN.md section 6).
        final Color resolved =
            pressed ? Color.alphaBlend(_pressedShade, glyphColor) : glyphColor;
        return NeuSurface.circle(
          diameter: diameter,
          pressed: pressed,
          child: ActionGlyph(
            kind: glyph,
            color: resolved,
            size: diameter * _glyphRatio,
          ),
        );
      },
    );
  }
}

/// 20% black overlay blended into the glyph when pressed.
const Color _pressedShade = Color(0x33000000);

/// Glyph occupies about half the button diameter.
const double _glyphRatio = 0.5;
