"""Passive traffic monitor for PadLink UDP.

Shows decoded input state, pings, and discovery queries reaching this
machine, without creating a virtual gamepad. Use it to prove the phone
is really sending packets, independent of server.py.

Usage:
    python monitor.py [--port 9876] [-v]
"""

from __future__ import annotations

import argparse
import socket
import sys
import time

sys.path.insert(0, __file__.rsplit("/", 1)[0])

from protocol import (  # noqa: E402
    DEFAULT_PORT,
    decode,
    decode_ping,
    encode_discovery_reply,
    is_discovery_query,
    is_ping,
    pressed_names,
)


def _local_ips() -> list[str]:
    """Non-loopback IPv4 addresses for the 'connect to' hint. Best effort."""
    ips: set[str] = set()
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.connect(("8.8.8.8", 80))
        ips.add(sock.getsockname()[0])
        sock.close()
    except OSError:
        pass
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ip = info[4][0]
            if not ip.startswith("127."):
                ips.add(ip)
    except OSError:
        pass
    return sorted(ips)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="PadLink UDP traffic monitor")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="also print stick motion"
    )
    args = parser.parse_args(argv)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", args.port))
    sock.settimeout(0.5)
    print(f"listening on udp 0.0.0.0:{args.port} (Ctrl-C to stop)")
    addrs = _local_ips()
    if addrs:
        print(f"connect the app to: {', '.join(addrs)} (port {args.port})")
    print("press buttons / move sticks on the phone...")

    counts = {"input": 0, "ping": 0, "discovery": 0, "invalid": 0}
    last_buttons: int | None = None
    try:
        while True:
            try:
                data, addr = sock.recvfrom(256)
            except socket.timeout:
                continue
            stamp = time.strftime("%H:%M:%S")
            if is_ping(data):
                counts["ping"] += 1
                sock.sendto(data, addr)
                print(f"{stamp} ping nonce={decode_ping(data)} from {addr[0]} (echoed)")
            elif is_discovery_query(data):
                counts["discovery"] += 1
                reply = encode_discovery_reply(args.port, socket.gethostname())
                sock.sendto(reply, addr)
                print(f"{stamp} discovery query from {addr[0]} (replied)")
            else:
                try:
                    state = decode(data)
                except ValueError:
                    counts["invalid"] += 1
                    print(f"{stamp} invalid {len(data)}B from {addr[0]}")
                    continue
                counts["input"] += 1
                names = pressed_names(state.buttons)
                btn = "+".join(names) if names else "(none)"
                if state.buttons != last_buttons:
                    print(
                        f"{stamp} buttons={btn} "
                        f"l2={state.l2} r2={state.r2} "
                        f"lx={state.lx} ly={state.ly} "
                        f"rx={state.rx} ry={state.ry} from {addr[0]}"
                    )
                    last_buttons = state.buttons
                elif args.verbose:
                    print(
                        f"{stamp} axes l2={state.l2} r2={state.r2} "
                        f"lx={state.lx} ly={state.ly} "
                        f"rx={state.rx} ry={state.ry}"
                    )
    except KeyboardInterrupt:
        pass
    print(f"summary: {counts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
