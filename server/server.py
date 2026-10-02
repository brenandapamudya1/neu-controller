"""PadLink UDP server entry point (Linux M0).

Listens for v1 packets, validates them, updates the virtual gamepad.
Failsafe: no packet for 500 ms -> backend.reset().
"""

from __future__ import annotations

import argparse
import asyncio
import logging
import sys
import time

sys.path.insert(0, __file__.rsplit("/", 1)[0])

from protocol import (  # noqa: E402
    DEFAULT_PORT,
    FAILSAFE_TIMEOUT_S,
    InputState,
    decode,
    is_seq_newer,
)

log = logging.getLogger("padlink")


class PadLinkProtocol(asyncio.DatagramProtocol):
    """Asyncio UDP handler. Pure validation + backend update."""

    def __init__(self, backend) -> None:
        self.backend = backend
        self.last_seq: int | None = None
        self.last_time: float = 0.0
        self.client_addr = None
        self.received = 0
        self.dropped = 0

    def datagram_received(self, data: bytes, addr) -> None:
        try:
            state: InputState = decode(data)
        except ValueError as exc:
            self.dropped += 1
            log.debug("drop invalid packet from %s: %s", addr, exc)
            return

        if not is_seq_newer(self.last_seq, state.seq):
            self.dropped += 1
            log.debug("drop old seq %s (last %s) from %s", state.seq, self.last_seq, addr)
            return

        if self.client_addr != addr:
            log.info("client connected: %s", addr)
            self.client_addr = addr
        self.last_seq = state.seq
        self.last_time = time.monotonic()
        self.received += 1
        try:
            self.backend.update(state)
        except Exception:  # noqa: BLE001 - keep server alive on backend errors
            log.exception("backend update failed")
            self.dropped += 1


async def _failsafe_loop(proto: PadLinkProtocol, timeout: float = FAILSAFE_TIMEOUT_S) -> None:
    """Reset backend if no fresh packet within timeout."""
    was_connected = False
    while True:
        await asyncio.sleep(0.1)
        if proto.client_addr is None:
            continue
        idle = time.monotonic() - proto.last_time
        if idle >= timeout:
            if was_connected or proto.last_seq is not None:
                log.warning("failsafe: no packet for %.2fs, resetting inputs", idle)
                try:
                    proto.backend.reset()
                except Exception:  # noqa: BLE001
                    log.exception("backend reset failed")
                proto.last_seq = None
                was_connected = False
        else:
            was_connected = True


def create_backend(dry_run: bool):
    if dry_run:
        from backends import LoggingBackend

        log.info("using dry-run logging backend (no virtual device)")
        return LoggingBackend()
    try:
        from backends.linux_uinput import LinuxUinputBackend

        return LinuxUinputBackend()
    except RuntimeError as exc:
        log.error("%s", exc)
        log.error("Hint: run with --dry-run to test networking without /dev/uinput.")
        raise SystemExit(2) from exc


async def _amain(host: str, port: int, dry_run: bool) -> None:
    backend = create_backend(dry_run)
    loop = asyncio.get_running_loop()
    proto = PadLinkProtocol(backend)
    transport, _ = await loop.create_datagram_endpoint(
        lambda: proto, local_addr=(host, port)
    )
    log.info("listening on udp %s:%d (dry_run=%s)", host, port, dry_run)
    failsafe = asyncio.ensure_future(_failsafe_loop(proto))
    try:
        await asyncio.Future()  # run forever
    except (asyncio.CancelledError, KeyboardInterrupt):
        pass
    finally:
        failsafe.cancel()
        transport.close()
        backend.close()


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="PadLink UDP server (Linux M0)")
    parser.add_argument("--host", default="0.0.0.0", help="listen address")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="udp port")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="log packets without creating /dev/uinput device",
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    try:
        asyncio.run(_amain(args.host, args.port, args.dry_run))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
