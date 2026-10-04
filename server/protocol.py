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
import sys
from dataclasses import dataclass

MAGIC: bytes = b"\x50\x4C"
VERSION: int = 1
PACKET_SIZE: int = 13
DEFAULT_PORT: int = 9876
FAILSAFE_TIMEOUT_S: float = 0.5

# Auxiliary ping (latency probe). Separate message type on the same UDP
# socket; echo the datagram back unchanged. Does NOT alter the v1 input
# format above, so no version bump is needed.
PING_MAGIC: bytes = b"\x50\x4C\x70\x67"  # "PLpg"
PING_SIZE: int = 12  # 4 magic + 8 nonce (uint64 LE)

# Server discovery (M3). App broadcasts a 5-byte query; each server
# replies directly with its input port and hostname. Same socket,
# separate message type, no version bump.
DISC_MAGIC: bytes = b"\x50\x4C\x64\x73"  # "PLds"
DISC_VERSION: int = 1
DISC_QUERY_SIZE: int = 5  # 4 magic + 1 version
DISC_MAX_NAME: int = 64

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

#: Human-readable names per button bit, for server input logging.
BTN_NAMES: dict[int, str] = {
    0: "Cross",
    1: "Circle",
    2: "Square",
    3: "Triangle",
    4: "L1",
    5: "R1",
    6: "L3",
    7: "R3",
    8: "DUp",
    9: "DDown",
    10: "DLeft",
    11: "DRight",
    12: "Options",
    13: "Share",
    14: "Home",
}


def pressed_names(buttons: int) -> list[str]:
    """Return names of set bits, e.g. [\"Cross\", \"L1\"]. Empty when none."""
    return [BTN_NAMES[bit] for bit in range(15) if buttons & (1 << bit)]

AXIS_MIN: int = -127
AXIS_MAX: int = 127
TRIGGER_MIN: int = 0
TRIGGER_MAX: int = 255

_STRUCT = struct.Struct("<2sBHHBBbbbb")
_PING_STRUCT = struct.Struct("<4sQ")
_DISC_QUERY_STRUCT = struct.Struct("<4sB")
_DISC_REPLY_STRUCT = struct.Struct("<4sBH")


_dc_kwargs = {"frozen": True}
if sys.version_info >= (3, 10):
    _dc_kwargs["slots"] = True


@dataclass(**_dc_kwargs)
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


def is_ping(data: bytes | bytearray | memoryview) -> bool:
    """True if `data` is a well-formed ping probe (not a v1 packet)."""
    if len(data) != PING_SIZE:
        return False
    return bytes(data[:4]) == PING_MAGIC


def encode_ping(nonce: int) -> bytes:
    """Build a 12-byte ping probe carrying `nonce` (uint64)."""
    return _PING_STRUCT.pack(PING_MAGIC, int(nonce) & 0xFFFFFFFFFFFFFFFF)


def decode_ping(data: bytes | bytearray | memoryview) -> int:
    """Return the nonce of a ping probe. Raises ValueError if malformed."""
    if len(data) != PING_SIZE:
        raise ValueError(f"invalid ping length: expected {PING_SIZE}, got {len(data)}")
    magic, nonce = _PING_STRUCT.unpack(bytes(data))
    if magic != PING_MAGIC:
        raise ValueError(f"invalid ping magic: {magic!r}")
    return nonce


def is_discovery_query(data: bytes | bytearray | memoryview) -> bool:
    """True if `data` is a well-formed discovery query."""
    if len(data) != DISC_QUERY_SIZE:
        return False
    magic, version = _DISC_QUERY_STRUCT.unpack(bytes(data))
    return magic == DISC_MAGIC and version == DISC_VERSION


def encode_discovery_query() -> bytes:
    """Build the 5-byte broadcast query the app sends."""
    return _DISC_QUERY_STRUCT.pack(DISC_MAGIC, DISC_VERSION)


def encode_discovery_reply(port: int, name: str) -> bytes:
    """Build a discovery reply: magic + version + input port + hostname."""
    raw = name.encode("utf-8")[:DISC_MAX_NAME]
    return _DISC_REPLY_STRUCT.pack(DISC_MAGIC, DISC_VERSION, int(port) & 0xFFFF) + raw


def decode_discovery_reply(data: bytes | bytearray | memoryview) -> tuple[int, str]:
    """Return (input port, server name) of a discovery reply."""
    data = bytes(data)
    if len(data) < _DISC_REPLY_STRUCT.size:
        raise ValueError(f"discovery reply too short: {len(data)}")
    magic, version, port = _DISC_REPLY_STRUCT.unpack(data[: _DISC_REPLY_STRUCT.size])
    if magic != DISC_MAGIC:
        raise ValueError(f"invalid discovery magic: {magic!r}")
    if version != DISC_VERSION:
        raise ValueError(f"unsupported discovery version: {version}")
    name = data[_DISC_REPLY_STRUCT.size :][:DISC_MAX_NAME].decode("utf-8", errors="replace")
    return port, name
