// Small center pill buttons: Share, Home, Options (DESIGN.md section 1).
// v1 uses on/off mode; layout and behavior mirror ShoulderButton.

import 'package:flutter/widgets.dart';

import '../../core/theme.dart';
import 'neu_pressable.dart';
import 'neu_surface.dart';

/// 48x24 pill for Share/Home/Options. Reports press via onChanged.
class CenterButton extends StatelessWidget {
  final String label;
  final ValueChanged<bool>? onChanged;
  final bool haptic;

  const CenterButton({
    super.key,
    required this.label,
    this.onChanged,
    this.haptic = true,
  });

  @override
  Widget build(BuildContext context) {
    final NeuPalette palette = NeuTheme.of(context);
    return NeuPressable(
      onChanged: onChanged,
      haptic: haptic,
      semanticLabel: label,
      builder: (BuildContext context, bool pressed) {
        return NeuSurface(
          width: NeuSizes.centerWidth,
          height: NeuSizes.centerHeight,
          pressed: pressed,
          small: true,
          borderRadius: NeuSizes.pillRadius,
          child: Text(
            label,
            style: TextStyle(
              color: pressed ? palette.accent : palette.textMuted,
              fontSize: NeuSizes.labelMinFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
