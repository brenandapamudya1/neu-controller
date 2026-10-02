"""Gamepad backend interface. server.py must only use this, never evdev directly."""

from __future__ import annotations

from typing import TYPE_CHECKING, Protocol as TypingProtocol

if TYPE_CHECKING:
    from ..protocol import InputState


class GamepadBackend(TypingProtocol):
    """Platform backend behind a single interface."""

    def update(self, state: InputState) -> None:
        """Push new full state to the virtual gamepad."""
        ...

    def reset(self) -> None:
        """Release all buttons and center sticks (failsafe)."""
        ...

    def close(self) -> None:
        """Release OS resources."""
        ...


class LoggingBackend:
    """Dry-run backend: logs states, drives no virtual device."""

    def __init__(self) -> None:
        self.last: InputState | None = None
        self.reset_count: int = 0

    def update(self, state: InputState) -> None:
        self.last = state

    def reset(self) -> None:
        self.reset_count += 1
        self.last = None

    def close(self) -> None:
        pass
