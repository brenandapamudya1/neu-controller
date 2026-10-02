// Pill shoulder buttons L1/L2/R1/R2 with text labels.
// v1 uses on/off mode (DESIGN.md section 3); analog slide comes later.

import 'package:flutter/widgets.dart';

import '../../core/theme.dart';
import 'neu_pressable.dart';
import 'neu_surface.dart';

/// Which shoulder control this button represents.
enum ShoulderKind {
  l1,
  l2,
  l3,
  r1,
  r2,
  r3,
}

/// Pill button for L1/L2/L3/R1/R2/R3. Sizes come from NeuSizes, never literals.
class ShoulderButton extends StatelessWidget {
  final ShoulderKind kind;
  final ValueChanged<bool>? onChanged;
  final bool haptic;

  const ShoulderButton({
    super.key,
    required this.kind,
    this.onChanged,
    this.haptic = true,
  });

  String get label {
    switch (kind) {
      case ShoulderKind.l1:
        return 'L1';
      case ShoulderKind.l2:
        return 'L2';
      case ShoulderKind.l3:
        return 'L3';
      case ShoulderKind.r1:
        return 'R1';
      case ShoulderKind.r2:
        return 'R2';
      case ShoulderKind.r3:
        return 'R3';
    }
  }

  double get width {
    switch (kind) {
      case ShoulderKind.l1:
      case ShoulderKind.r1:
      case ShoulderKind.l3:
      case ShoulderKind.r3:
        return NeuSizes.l1r1Width;
      case ShoulderKind.l2:
      case ShoulderKind.r2:
        return NeuSizes.l2r2Width;
    }
  }

  double get height {
    switch (kind) {
      case ShoulderKind.l1:
      case ShoulderKind.r1:
      case ShoulderKind.l3:
      case ShoulderKind.r3:
        return NeuSizes.l1r1Height;
      case ShoulderKind.l2:
      case ShoulderKind.r2:
        return NeuSizes.l2r2Height;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text = label;
    final NeuPalette palette = NeuTheme.of(context);
    return NeuPressable(
      onChanged: onChanged,
      haptic: haptic,
      semanticLabel: text,
      builder: (BuildContext context, bool pressed) {
        return NeuSurface(
          width: width,
          height: height,
          pressed: pressed,
          small: true,
          borderRadius: NeuSizes.pillRadius,
          child: Text(
            text,
            style: TextStyle(
              color: pressed ? palette.accent : palette.textMuted,
              fontSize: NeuSizes.controlLabelFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
