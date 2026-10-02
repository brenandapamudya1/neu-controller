// Base neumorphic container with raised/pressed states.
// Raised uses dual outer BoxShadow. Pressed simulates an inset concave
// surface with a CustomPainter (no extra dependency), plus a slightly
// darker background. Transition follows NeuMotion.press (70 ms, easeOut).

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Shape rendered by [NeuSurface].
enum NeuSurfaceShape {
  circle,
  roundedRect,
}

class NeuSurface extends StatelessWidget {
  final Widget? child;
  final bool pressed;
  final double? width;
  final double? height;
  final NeuSurfaceShape shape;
  final double borderRadius;
  final bool small;

  /// Null means "use the active [NeuTheme] palette".
  final Color? color;
  final Color? pressedColor;
  final EdgeInsetsGeometry? padding;

  const NeuSurface({
    super.key,
    this.child,
    this.pressed = false,
    this.width,
    this.height,
    this.shape = NeuSurfaceShape.roundedRect,
    this.borderRadius = NeuSizes.defaultRadius,
    this.small = false,
    this.color,
    this.pressedColor,
    this.padding,
  });

  /// Circular surface, e.g. action buttons and joystick base/knob.
  const NeuSurface.circle({
    super.key,
    this.child,
    this.pressed = false,
    double diameter = NeuSizes.actionDefault,
    this.small = false,
    this.color,
    this.pressedColor,
    this.padding,
  })  : width = diameter,
        height = diameter,
        shape = NeuSurfaceShape.circle,
        borderRadius = 0;

  @override
  Widget build(BuildContext context) {
    final NeuPalette palette = NeuTheme.of(context);
    final bool isCircle = shape == NeuSurfaceShape.circle;
    final List<BoxShadow> shadows = pressed
        ? const []
        : (small
            ? NeuShadows.raisedSmall(
                dark: palette.shadowDark, light: palette.shadowLight)
            : NeuShadows.raised(
                dark: palette.shadowDark, light: palette.shadowLight));

    return AnimatedContainer(
      duration: NeuMotion.press,
      curve: NeuMotion.pressCurve,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: pressed ? (pressedColor ?? palette.bgPressed) : (color ?? palette.bg),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: NeuMotion.press,
              curve: NeuMotion.pressCurve,
              opacity: pressed ? 1 : 0,
              child: CustomPaint(
                painter: _NeuInsetPainter(
                  circle: isCircle,
                  radius: borderRadius,
                  shadowDark: palette.shadowDark,
                  shadowLight: palette.shadowLight,
                ),
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Paints inner concave shading: dark from top-left, light from
/// bottom-right, fading toward the center. Clipped to the surface shape.
class _NeuInsetPainter extends CustomPainter {
  final bool circle;
  final double radius;
  final Color shadowDark;
  final Color shadowLight;

  _NeuInsetPainter({
    required this.circle,
    required this.radius,
    required this.shadowDark,
    required this.shadowLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.save();
    if (circle) {
      canvas.clipPath(
        Path()..addOval(rect),
      );
    } else {
      canvas.clipRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      );
    }

    // Dark inner edge (top-left). Reversed vs raised outer shadow.
    final Paint dark = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.center,
        colors: [shadowDark.withAlpha(77), shadowDark.withAlpha(0)],
      ).createShader(rect);
    canvas.drawRect(rect, dark);

    // Light inner edge (bottom-right).
    final Paint light = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.center,
        colors: [shadowLight.withAlpha(153), shadowLight.withAlpha(0)],
      ).createShader(rect);
    canvas.drawRect(rect, light);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeuInsetPainter oldDelegate) {
    return oldDelegate.circle != circle ||
        oldDelegate.radius != radius ||
        oldDelegate.shadowDark != shadowDark ||
        oldDelegate.shadowLight != shadowLight;
  }
}
