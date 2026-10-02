"""M3b discovery tests: query/reply round-trip, validation, server reply."""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from protocol import (  # noqa: E402
    DISC_MAGIC,
    decode_discovery_reply,
    encode_discovery_query,
    encode_discovery_reply,
    is_discovery_query,
)


def test_discovery_query_layout():
    data = encode_discovery_query()
    assert len(data) == 5
    assert data[:4] == DISC_MAGIC
    assert is_discovery_query(data)


def test_discovery_reply_round_trip():
    port, name = decode_discovery_reply(encode_discovery_reply(9876, "laptop"))
    assert (port, name) == (9876, "laptop")


def test_discovery_reply_truncates_long_names():
    port, name = decode_discovery_reply(encode_discovery_reply(1, "x" * 200))
    assert port == 1
    assert len(name.encode("utf-8")) <= 64


def test_discovery_rejects_malformed():
    for bad in (b"", b"PLds", b"\x00" * 7, b"\x50\x4Cping1234!"):
        assert not is_discovery_query(bad)
    for bad in (b"", b"PL", b"\x00" * 7):
        try:
            decode_discovery_reply(bad)
            assert False, f"should raise for {bad!r}"
        except ValueError:
            pass


def test_server_replies_to_discovery():
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
    proto = PadLinkProtocol(backend, port=9999)
    transport = FakeTransport()
    proto.connection_made(transport)

    addr = ("192.168.1.9", 54321)
    proto.datagram_received(encode_discovery_query(), addr)

    assert len(transport.sent) == 1
    data, to = transport.sent[0]
    assert to == addr
    port, name = decode_discovery_reply(data)
    assert port == 9999
    assert name  # hostname non-empty
    # Input state untouched.
    assert backend.updates == []
    assert proto.received == 0
    assert proto.discoveries == 1
