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
  final Color color;
  final Color pressedColor;
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
    this.color = NeuColors.bg,
    this.pressedColor = NeuColors.bgPressed,
    this.padding,
  });

  /// Circular surface, e.g. action buttons and joystick base/knob.
  const NeuSurface.circle({
    super.key,
    this.child,
    this.pressed = false,
    double diameter = NeuSizes.actionDefault,
    this.small = false,
    this.color = NeuColors.bg,
    this.pressedColor = NeuColors.bgPressed,
    this.padding,
  })  : width = diameter,
        height = diameter,
        shape = NeuSurfaceShape.circle,
        borderRadius = 0;

  @override
  Widget build(BuildContext context) {
    final bool isCircle = shape == NeuSurfaceShape.circle;
    final List<BoxShadow> shadows =
        pressed ? const [] : (small ? NeuShadows.raisedSmall() : NeuShadows.raised());

    return AnimatedContainer(
      duration: NeuMotion.press,
      curve: NeuMotion.pressCurve,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: pressed ? pressedColor : color,
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

  _NeuInsetPainter({required this.circle, required this.radius});

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
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.center,
        colors: [Color(0x4DA3B1C6), Color(0x00A3B1C6)],
      ).createShader(rect);
    canvas.drawRect(rect, dark);

    // Light inner edge (bottom-right).
    final Paint light = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.center,
        colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
      ).createShader(rect);
    canvas.drawRect(rect, light);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeuInsetPainter oldDelegate) {
    return oldDelegate.circle != circle || oldDelegate.radius != radius;
  }
}
