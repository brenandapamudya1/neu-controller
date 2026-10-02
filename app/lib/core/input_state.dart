// Single source of truth for controller inputs.
// Widgets only mutate this model; UdpSender reads it at 60 Hz.
// No networking code is allowed in widgets.

import 'package:flutter/foundation.dart';

/// Immutable full controller state (mirrors server/protocol.py v1).
@immutable
class InputState {
  final int seq;
  final int buttons;
  final int l2;
  final int r2;
  final int lx;
  final int ly;
  final int rx;
  final int ry;

  const InputState({
    this.seq = 0,
    this.buttons = 0,
    this.l2 = 0,
    this.r2 = 0,
    this.lx = 0,
    this.ly = 0,
    this.rx = 0,
    this.ry = 0,
  });

  InputState copyWith({
    int? seq,
    int? buttons,
    int? l2,
    int? r2,
    int? lx,
    int? ly,
    int? rx,
    int? ry,
  }) {
    return InputState(
      seq: seq ?? this.seq,
      buttons: buttons ?? this.buttons,
      l2: l2 ?? this.l2,
      r2: r2 ?? this.r2,
      lx: lx ?? this.lx,
      ly: ly ?? this.ly,
      rx: rx ?? this.rx,
      ry: ry ?? this.ry,
    );
  }
}

/// Button bitmask (must match PROJECT.md section 5).
class PadButtons {
  static const int cross = 1 << 0;
  static const int circle = 1 << 1;
  static const int square = 1 << 2;
  static const int triangle = 1 << 3;
  static const int l1 = 1 << 4;
  static const int r1 = 1 << 5;
  static const int l3 = 1 << 6;
  static const int r3 = 1 << 7;
  static const int dpadUp = 1 << 8;
  static const int dpadDown = 1 << 9;
  static const int dpadLeft = 1 << 10;
  static const int dpadRight = 1 << 11;
  static const int options = 1 << 12;
  static const int share = 1 << 13;
  static const int home = 1 << 14;
}

/// Mutable holder notified on every control change.
/// UdpSender listens to this and sends at a fixed rate.
class ControllerState extends ValueNotifier<InputState> {
  ControllerState() : super(const InputState());

  void setButton(int mask, bool pressed) {
    final current = value.buttons;
    final next = pressed ? (current | mask) : (current & ~mask);
    if (next != current) {
      value = value.copyWith(buttons: next);
    }
  }

  void reset() {
    value = const InputState();
  }
}
