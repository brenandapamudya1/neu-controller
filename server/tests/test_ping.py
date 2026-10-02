"""M3a ping tests: probe round-trip, validation, server echo."""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from protocol import (  # noqa: E402
    PING_MAGIC,
    PING_SIZE,
    decode_ping,
    encode_ping,
    is_ping,
)


def test_ping_round_trip():
    for nonce in (0, 1, 123456789, 2**64 - 1):
        assert decode_ping(encode_ping(nonce)) == nonce


def test_ping_layout():
    data = encode_ping(42)
    assert len(data) == PING_SIZE
    assert data[:4] == PING_MAGIC


def test_ping_rejects_malformed():
    for bad in (b"", b"PL", b"\x00" * PING_SIZE, b"\x50\x4Cping1234!"):
        try:
            decode_ping(bad)
            assert False, f"should raise for {bad!r}"
        except ValueError:
            pass
        assert not is_ping(bad)


def test_server_echoes_ping_without_state_change():
    from server import PadLinkProtocol

    class FakeBackend:
        def __init__(self):
            self.updates = []

        def update(self, state):
            self.updates.append(state)

        def reset(self):
            pass

        def close(self):
            pass

    class FakeTransport:
        def __init__(self):
            self.sent = []

        def sendto(self, data, addr):
            self.sent.append((bytes(data), addr))

    backend = FakeBackend()
    proto = PadLinkProtocol(backend)
    transport = FakeTransport()
    proto.connection_made(transport)

    addr = ("192.168.1.9", 54321)
    probe = encode_ping(777)
    proto.datagram_received(probe, addr)

    assert transport.sent == [(probe, addr)]
    # Input state untouched by probes.
    assert backend.updates == []
    assert proto.received == 0
    assert proto.last_seq is None
    assert proto.client_addr is None
