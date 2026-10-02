"""M0 protocol tests: round-trip, boundaries, invalid packets, seq handling."""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from protocol import (  # noqa: E402
    PACKET_SIZE,
    InputState,
    decode,
    encode,
    is_seq_newer,
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


def test_server_drops_old_seq_and_invalid():
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
    proto = PadLinkProtocol(backend)
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
