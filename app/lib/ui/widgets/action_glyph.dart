// Vector action glyphs (triangle, circle, cross, square).
// Drawn with CustomPainter per DESIGN.md section 7, never bitmaps.

import 'package:flutter/material.dart';

/// Which PlayStation-style glyph to draw.
enum ActionGlyphKind {
  triangle,
  circle,
  cross,
  square,
}

/// Fixed-size vector glyph. Color comes from NeuColors action tokens.
class ActionGlyph extends StatelessWidget {
  final ActionGlyphKind kind;
  final Color color;
  final double size;

  const ActionGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ActionGlyphPainter(kind: kind, color: color),
      ),
    );
  }
}

class _ActionGlyphPainter extends CustomPainter {
  final ActionGlyphKind kind;
  final Color color;

  _ActionGlyphPainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double side = size.shortestSide;
    // Stroke scales with glyph size so 56 dp and 64 dp buttons look alike.
    final double stroke = (side * 0.1).clamp(3.0, 7.0);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Offset center = size.center(Offset.zero);
    switch (kind) {
      case ActionGlyphKind.circle:
        canvas.drawCircle(center, side / 2 - stroke, paint);
      case ActionGlyphKind.square:
        final double half = side * 0.33;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: half * 2, height: half * 2),
            Radius.circular(half * 0.25),
          ),
          paint,
        );
      case ActionGlyphKind.triangle:
        final Path path = Path()
          ..moveTo(center.dx, stroke * 0.75)
          ..lineTo(side - stroke * 0.75, side - stroke * 0.75)
          ..lineTo(stroke * 0.75, side - stroke * 0.75)
          ..close();
        canvas.drawPath(path, paint);
      case ActionGlyphKind.cross:
        final double arm = side / 2 - stroke;
        canvas.drawLine(
          Offset(center.dx - arm, center.dy - arm),
          Offset(center.dx + arm, center.dy + arm),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx + arm, center.dy - arm),
          Offset(center.dx - arm, center.dy + arm),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ActionGlyphPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}
