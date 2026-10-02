"""PadLink v1 packet protocol.

Single packet carries full controller state, sent at 60 Hz.
Little-endian, 13 bytes total. Pure encode/decode, no side effects.

Layout (offset, size, field):
  0, 2 : magic 0x50 0x4C ("PL")
  2, 1 : version (1)
  3, 2 : seq uint16, increments per packet, used to drop late packets
  5, 2 : buttons bitmask uint16 (see BTN_* below)
  7, 1 : l2 0-255
  8, 1 : r2 0-255
  9, 1 : lx int8 -127..127
  10,1 : ly int8
  11,1 : rx int8
  12,1 : ry int8
"""

from __future__ import annotations

import struct
from dataclasses import dataclass

MAGIC: bytes = b"\x50\x4C"
VERSION: int = 1
PACKET_SIZE: int = 13
DEFAULT_PORT: int = 9876
FAILSAFE_TIMEOUT_S: float = 0.5

_SEQ_MOD: int = 1 << 16
_SEQ_HALF: int = 1 << 15

# Button bitmask (PROJECT.md section 5).
BTN_CROSS: int = 1 << 0
BTN_CIRCLE: int = 1 << 1
BTN_SQUARE: int = 1 << 2
BTN_TRIANGLE: int = 1 << 3
BTN_L1: int = 1 << 4
BTN_R1: int = 1 << 5
BTN_L3: int = 1 << 6
BTN_R3: int = 1 << 7
BTN_DPAD_UP: int = 1 << 8
BTN_DPAD_DOWN: int = 1 << 9
BTN_DPAD_LEFT: int = 1 << 10
BTN_DPAD_RIGHT: int = 1 << 11
BTN_OPTIONS: int = 1 << 12
BTN_SHARE: int = 1 << 13
BTN_HOME: int = 1 << 14
# Bit 15 reserved.

AXIS_MIN: int = -127
AXIS_MAX: int = 127
TRIGGER_MIN: int = 0
TRIGGER_MAX: int = 255

_STRUCT = struct.Struct("<2sBHHBBbbbb")


@dataclass(frozen=True, slots=True)
class InputState:
    """Full controller state carried by one packet."""

    seq: int
    buttons: int
    l2: int = 0
    r2: int = 0
    lx: int = 0
    ly: int = 0
    rx: int = 0
    ry: int = 0


def is_seq_newer(old: int | None, new: int) -> bool:
    """Return True if `new` seq is newer than `old`, handling uint16 wrap.

    Difference is computed modulo 2**16. A forward jump of
    1..32767 counts as newer, 0 (duplicate) or 32768..65535 counts as old.
    `None` (no packet seen yet) always returns True.
    """
    if old is None:
        return True
    diff = (new - old) & 0xFFFF
    return 0 < diff < _SEQ_HALF


def _clamp_axis(v: int) -> int:
    return max(AXIS_MIN, min(AXIS_MAX, int(v)))


def _clamp_trigger(v: int) -> int:
    return max(TRIGGER_MIN, min(TRIGGER_MAX, int(v)))


def encode(state: InputState) -> bytes:
    """Encode InputState to 13-byte v1 packet. Clamps axes/triggers."""
    seq = int(state.seq) & 0xFFFF
    buttons = int(state.buttons) & 0xFFFF
    return _STRUCT.pack(
        MAGIC,
        VERSION,
        seq,
        buttons,
        _clamp_trigger(state.l2),
        _clamp_trigger(state.r2),
        _clamp_axis(state.lx),
        _clamp_axis(state.ly),
        _clamp_axis(state.rx),
        _clamp_axis(state.ry),
    )


def decode(data: bytes | bytearray | memoryview) -> InputState:
    """Decode 13-byte v1 packet. Raises ValueError on invalid packet."""
    if len(data) != PACKET_SIZE:
        raise ValueError(f"invalid length: expected {PACKET_SIZE}, got {len(data)}")
    magic, version, seq, buttons, l2, r2, lx, ly, rx, ry = _STRUCT.unpack(bytes(data))
    if magic != MAGIC:
        raise ValueError(f"invalid magic: {magic!r}")
    if version != VERSION:
        raise ValueError(f"unsupported version: {version}")
    return InputState(
        seq=seq, buttons=buttons, l2=l2, r2=r2, lx=lx, ly=ly, rx=rx, ry=ry
    )
