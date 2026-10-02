// Design tokens from DESIGN.md section 2. Single source of truth.
// No magic numbers elsewhere: import sizes, colors, shadows from here.

import 'package:flutter/material.dart';

/// Light theme palette (DESIGN.md 2.1).
abstract final class NeuColors {
  static const Color bg = Color(0xFFE0E5EC);
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFA3B1C6);
  static const Color textMuted = Color(0xFF6B7A90);
  static const Color accent = Color(0xFF5B8DEF);
  static const Color ok = Color(0xFF2EBD85);
  static const Color warn = Color(0xFFF2A93B);
  static const Color error = Color(0xFFE5484D);

  // Action glyph colors (low-contrast neumorphism needs colored glyphs).
  static const Color triangle = Color(0xFF2EBD85);
  static const Color circle = Color(0xFFE5484D);
  static const Color cross = Color(0xFF5B8DEF);
  static const Color square = Color(0xFFD96FB0);

  /// Surface color when pressed: slightly darker than [bg].
  static const Color bgPressed = Color(0xFFD5DBE4);
}

/// Optional dark theme palette (DESIGN.md 2.2).
abstract final class NeuDarkColors {
  static const Color bg = Color(0xFF292D32);
  static const Color shadowLight = Color(0xFF33383E);
  static const Color shadowDark = Color(0xFF1F2226);
  static const Color bgPressed = Color(0xFF23262B);
}

/// Shadow geometry (DESIGN.md 2.3).
abstract final class NeuShadows {
  static const Offset raisedOffsetDark = Offset(6, 6);
  static const Offset raisedOffsetLight = Offset(-6, -6);
  static const double raisedBlur = 12;

  static const Offset smallOffsetDark = Offset(4, 4);
  static const Offset smallOffsetLight = Offset(-4, -4);
  static const double smallBlur = 8;

  static List<BoxShadow> raised({
    Color dark = NeuColors.shadowDark,
    Color light = NeuColors.shadowLight,
  }) {
    return [
      BoxShadow(
        color: dark,
        offset: raisedOffsetDark,
        blurRadius: raisedBlur,
      ),
      BoxShadow(
        color: light,
        offset: raisedOffsetLight,
        blurRadius: raisedBlur,
      ),
    ];
  }

  static List<BoxShadow> raisedSmall({
    Color dark = NeuColors.shadowDark,
    Color light = NeuColors.shadowLight,
  }) {
    return [
      BoxShadow(
        color: dark,
        offset: smallOffsetDark,
        blurRadius: smallBlur,
      ),
      BoxShadow(
        color: light,
        offset: smallOffsetLight,
        blurRadius: smallBlur,
      ),
    ];
  }
}

/// Shapes and sizes in dp (DESIGN.md 2.3). Touch target min 48 dp.
abstract final class NeuSizes {
  static const double actionMin = 56;
  static const double actionMax = 64;
  static const double actionDefault = 60;

  static const double dpadTotal = 150;

  static const double stickBaseMin = 130;
  static const double stickBaseMax = 150;
  static const double stickBaseDefault = 140;
  static const double stickKnobMin = 60;
  static const double stickKnobMax = 70;
  static const double stickKnobDefault = 64;

  static const double l1r1Width = 80;
  static const double l1r1Height = 36;
  static const double l2r2Width = 80;
  static const double l2r2Height = 44;
  static const double centerWidth = 48;
  static const double centerHeight = 24;

  static const double minTouchTarget = 48;
  static const double labelMinFontSize = 12;
  static const double controlLabelFontSize = 13;

  static const double defaultRadius = 16;
  static const double pillRadius = 999;
}

/// Animation spec (DESIGN.md 4). Responsiveness first.
abstract final class NeuMotion {
  static const Duration press = Duration(milliseconds: 70);
  static const Curve pressCurve = Curves.easeOut;
  static const Duration knobReturn = Duration(milliseconds: 120);
  static const Curve knobReturnCurve = Curves.easeOutBack;
}
