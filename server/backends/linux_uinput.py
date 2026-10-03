"""Linux uinput backend (python-evdev)."""

from __future__ import annotations

import logging

log = logging.getLogger(__name__)

# Button bit -> evdev code name. Names resolved lazily so module imports
# without evdev installed (allows dry-run / tests on any machine).
_BUTTON_MAP: dict[int, str] = {
    0: "BTN_SOUTH",  # Cross (PS) / A (Xbox)
    1: "BTN_EAST",  # Circle / B
    2: "BTN_NORTH",  # Square / X
    3: "BTN_WEST",  # Triangle / Y
    4: "BTN_TL",  # L1
    5: "BTN_TR",  # R1
    6: "BTN_THUMBL",  # L3
    7: "BTN_THUMBR",  # R3
    8: "BTN_DPAD_UP",
    9: "BTN_DPAD_DOWN",
    10: "BTN_DPAD_LEFT",
    11: "BTN_DPAD_RIGHT",
    12: "BTN_START",  # Options
    13: "BTN_SELECT",  # Share
    14: "BTN_MODE",  # PS/Home
}


class LinuxUinputBackend:
    """Virtual gamepad via /dev/uinput. Requires python-evdev + permission."""

    def __init__(self) -> None:
        try:
            from evdev import AbsInfo, UInput, ecodes
        except ImportError as exc:
            raise RuntimeError(
                "python-evdev not installed. Run: pip install -r requirements.txt"
            ) from exc

        self._ecodes = ecodes
        key_codes = sorted(
            {ecodes.ecodes[name] for name in _BUTTON_MAP.values()}
        )

        # Sticks use protocol range directly (-127..127) to avoid rescaling.
        # Triggers use 0..255.
        abs_caps = [
            (ecodes.ABS_X, AbsInfo(value=0, min=-127, max=127, fuzz=0, flat=8, resolution=0)),
            (ecodes.ABS_Y, AbsInfo(value=0, min=-127, max=127, fuzz=0, flat=8, resolution=0)),
            (ecodes.ABS_RX, AbsInfo(value=0, min=-127, max=127, fuzz=0, flat=8, resolution=0)),
            (ecodes.ABS_RY, AbsInfo(value=0, min=-127, max=127, fuzz=0, flat=8, resolution=0)),
            (ecodes.ABS_Z, AbsInfo(value=0, min=0, max=255, fuzz=0, flat=0, resolution=0)),
            (ecodes.ABS_RZ, AbsInfo(value=0, min=0, max=255, fuzz=0, flat=0, resolution=0)),
        ]
        capabilities = {ecodes.EV_KEY: key_codes, ecodes.EV_ABS: abs_caps}

        try:
            self._ui = UInput(capabilities, name="PadLink", version=0x1)
        except Exception as exc:
            raise RuntimeError(
                "Cannot open /dev/uinput. Need access (udev rule or group "
                "'input'), or run with --dry-run. "
                f"Underlying error: {exc}"
            ) from exc

        self._pressed: set[int] = set()
        log.info("Linux uinput device created: PadLink")

    def update(self, state) -> None:  # InputState, untyped to avoid import cycle
        ecodes = self._ecodes
        ui = self._ui

        # Buttons: diff against pressed set to only emit changes.
        wanted = set()
        for bit in range(15):
            if state.buttons & (1 << bit):
                code_name = _BUTTON_MAP.get(bit)
                if code_name is None:
                    continue
                wanted.add(ecodes.ecodes[code_name])
        for code in wanted - self._pressed:
            ui.write(ecodes.EV_KEY, code, 1)
        for code in self._pressed - wanted:
            ui.write(ecodes.EV_KEY, code, 0)
        self._pressed = wanted

        # Axes + triggers.
        ui.write(ecodes.EV_ABS, ecodes.ABS_X, int(state.lx))
        ui.write(ecodes.EV_ABS, ecodes.ABS_Y, int(state.ly))
        ui.write(ecodes.EV_ABS, ecodes.ABS_RX, int(state.rx))
        ui.write(ecodes.EV_ABS, ecodes.ABS_RY, int(state.ry))
        ui.write(ecodes.EV_ABS, ecodes.ABS_Z, int(state.l2))
        ui.write(ecodes.EV_ABS, ecodes.ABS_RZ, int(state.r2))
        ui.syn()

    def reset(self) -> None:
        ecodes = self._ecodes
        ui = self._ui
        for code in list(self._pressed):
            ui.write(ecodes.EV_KEY, code, 0)
        self._pressed.clear()
        ui.write(ecodes.EV_ABS, ecodes.ABS_X, 0)
        ui.write(ecodes.EV_ABS, ecodes.ABS_Y, 0)
        ui.write(ecodes.EV_ABS, ecodes.ABS_RX, 0)
        ui.write(ecodes.EV_ABS, ecodes.ABS_RY, 0)
        ui.write(ecodes.EV_ABS, ecodes.ABS_Z, 0)
        ui.write(ecodes.EV_ABS, ecodes.ABS_RZ, 0)
        ui.syn()

    def close(self) -> None:
        try:
            self._ui.close()
        except Exception:  # noqa: BLE001 - best effort on shutdown
            pass
