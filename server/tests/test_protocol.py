"""M0 protocol tests: round-trip, boundaries, invalid packets, seq handling."""

import logging
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from protocol import (  # noqa: E402
    PACKET_SIZE,
    InputState,
    decode,
    encode,
    is_seq_newer,
    pressed_names,
)


def test_round_trip_all_fields():
    s = InputState(seq=42, buttons=0xABCD, l2=255, r2=128, lx=-127, ly=127, rx=-1, ry=1)
    assert decode(encode(s)) == s


def test_boundary_values():
    for v in (-127, 127, 0):
        s = InputState(seq=1, buttons=0, lx=v, ly=v, rx=v, ry=v)
        assert decode(encode(s)).lx == v
    for t in (0, 255):
        s = InputState(seq=1, buttons=0, l2=t, r2=t)
        d = decode(encode(s))
        assert (d.l2, d.r2) == (t, t)


def test_bitmask_each_button():
    for bit in range(15):
        s = InputState(seq=bit, buttons=1 << bit)
        assert decode(encode(s)).buttons == 1 << bit


def test_pressed_names():
    assert pressed_names(0) == []
    assert pressed_names(1 << 0) == ["Cross"]
    assert pressed_names((1 << 0) | (1 << 4)) == ["Cross", "L1"]
    assert len(pressed_names(0x7FFF)) == 15


def test_invalid_packets_dropped():
    s = InputState(seq=1, buttons=1)
    good = bytearray(encode(s))
    # Wrong length.
    try:
        decode(bytes(good[:5]))
        assert False, "should raise on short packet"
    except ValueError:
        pass
    # Bad magic.
    bad = bytearray(good)
    bad[0] = 0x00
    try:
        decode(bytes(bad))
        assert False, "should raise on bad magic"
    except ValueError:
        pass
    # Bad version.
    bad = bytearray(good)
    bad[2] = 0xFF
    try:
        decode(bytes(bad))
        assert False, "should raise on bad version"
    except ValueError:
        pass


def test_seq_newer_basic():
    assert is_seq_newer(None, 0) is True
    assert is_seq_newer(10, 11) is True
    assert is_seq_newer(10, 10) is False  # duplicate
    assert is_seq_newer(11, 10) is False  # old


def test_seq_wrap_around():
    assert is_seq_newer(65535, 0) is True
    assert is_seq_newer(65535, 1) is True
    assert is_seq_newer(0, 65535) is False  # late packet from before wrap
    assert is_seq_newer(100, 100 + 32767) is True
    assert is_seq_newer(100, 100 + 32768) is False


def _make_proto():
    from server import PadLinkProtocol

    class FakeBackend:
        def __init__(self):
            self.updates = []
            self.resets = 0

        def update(self, state):
            self.updates.append(state)

        def reset(self):
            self.resets += 1

        def close(self):
            pass

    backend = FakeBackend()
    return PadLinkProtocol(backend), backend


def test_server_drops_old_seq_and_invalid():
    proto, backend = _make_proto()
    addr = ("127.0.0.1", 1234)

    proto.datagram_received(encode(InputState(seq=10, buttons=1)), addr)
    assert len(backend.updates) == 1
    # Old seq dropped.
    proto.datagram_received(encode(InputState(seq=9, buttons=2)), addr)
    assert len(backend.updates) == 1
    assert proto.dropped >= 1
    # Invalid dropped.
    proto.datagram_received(b"junk", addr)
    assert len(backend.updates) == 1
    # Newer accepted.
    proto.datagram_received(encode(InputState(seq=11, buttons=4)), addr)
    assert len(backend.updates) == 2


def test_server_logs_button_changes_at_info(caplog):
    proto, _ = _make_proto()
    addr = ("127.0.0.1", 1234)

    with caplog.at_level(logging.INFO, logger="padlink"):
        proto.datagram_received(encode(InputState(seq=1, buttons=0)), addr)
        assert any("buttons: (none)" in r.message for r in caplog.records)
        caplog.clear()
        # Same buttons again: no repeat INFO.
        proto.datagram_received(encode(InputState(seq=2, buttons=0)), addr)
        assert not [r for r in caplog.records if r.message.startswith("buttons:")]
        # New press: INFO with names.
        proto.datagram_received(
            encode(InputState(seq=3, buttons=(1 << 0) | (1 << 4))), addr
        )
        assert any("buttons: Cross+L1" in r.message for r in caplog.records)


def test_server_logs_axes_only_at_debug(caplog):
    proto, _ = _make_proto()
    addr = ("127.0.0.1", 1234)
    proto.datagram_received(encode(InputState(seq=1, buttons=1, lx=0)), addr)

    with caplog.at_level(logging.DEBUG, logger="padlink"):
        caplog.clear()
        proto.datagram_received(encode(InputState(seq=2, buttons=1, lx=50)), addr)
        assert any(r.message.startswith("axes:") for r in caplog.records)
        assert not [r for r in caplog.records if r.message.startswith("buttons:")]
