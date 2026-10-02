# PadLink — Phone as a laptop gamepad

A Flutter app that turns your phone into a gamepad for laptop games.
The phone streams input state over UDP (60 Hz); a Python server on the
laptop translates it into a virtual gamepad.

```
[Phone: Flutter app] --UDP 9876--> [Laptop: server.py] --> [virtual gamepad] --> Game
```

> Status: v1 feature-complete on Linux (M0–M3). The Windows backend
> (`ViGEmBus`) and M4 (gyro, Bluetooth HID, iOS) are not implemented yet.

## Quick setup (< 2 minutes)

You need: an Android phone + a Linux laptop on the same network
(or the phone hotspot — recommended), plus the server below running
on the laptop. Without the server, the app cannot do anything.

**1. Laptop — start the server:**
```bash
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python server.py --port 9876
# note the "connect the app to: <IP>:9876" line
```

One-time permission on Linux (access to `/dev/uinput`):
```bash
sudo usermod -aG input $USER   # then log out / log back in
sudo ufw allow 9876/udp        # if the firewall is active
```

**2. Phone — run the app:**
```bash
cd app
flutter pub get
flutter run            # pick the Android device (USB debugging on)
```

**3. In the app:** Connect screen → "Nearby servers" list → tap the
laptop name (or enter the IP manually) → Connect → play. A green
status under 30 ms means a healthy link.

Without building from source, replace the phone step with: install
the APK from `flutter build apk`, then follow step 3.

## Download APK (no build needed)

Tagged versions publish a ready-to-install APK on the
[Releases page](https://github.com/brenandapamudya1/neu-controller/releases):

1. On the phone, open the latest release and download the
   `padlink-v*.apk` file.
2. Allow "Install unknown apps" once when prompted, then install.
3. Start the laptop server first (step 1 above), then Connect in the app.

Every push to `master` also builds an APK automatically (Actions tab →
latest `build-apk` run → Artifacts), so testers never need the SDK.

## Verify the virtual gamepad

```bash
sudo evtest            # pick the "PadLink" device, press phone buttons
# or: jstest /dev/input/js0
```

v1 acceptance checklist (PRD §7):
- [ ] Games recognize the virtual device as a gamepad.
- [ ] Two buttons + one stick work simultaneously without dropouts.
- [ ] Killing WiFi/app returns all inputs to neutral within ≤ 1 second (failsafe).
- [ ] All controls (sticks, D-pad, action, shoulders) work on Android.
- [ ] Hotspot + manual IP setup works from scratch.

## Troubleshooting

| Symptom | Common cause | Fix |
|---|---|---|
| Empty server list | Broadcast blocked / WiFi client isolation (campus/cafe) | Enter the IP manually from the server log; or use the phone hotspot |
| Connected but pill stays red | Laptop firewall blocks UDP | `sudo ufw allow 9876/udp`; check `server.py --dry-run` receives pings |
| `Cannot open /dev/uinput` | `input` group / udev | `usermod -aG input`, relogin; fallback: `--dry-run` for network-only tests |
| "Stuck" buttons | Packet loss on disconnect | The 500 ms failsafe resets automatically; do not disable it. Report if it happens |
| Yellow/red latency | Busy WiFi, long distance | Move devices closer, use the phone hotspot, stop big downloads |
| Windows | Backend missing | v1 = Linux first; Windows needs `backends/windows_vgamepad.py` + the ViGEmBus driver |

## For developers

```bash
cd app && flutter analyze && flutter test        # 57+ widget tests
cd server && source .venv/bin/activate \
  && PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python -m pytest tests/ -q
python server.py --dry-run --port 9876           # network test without hardware
```

Layout: `app/lib/{core,network,ui,settings}` (Flutter),
`server/{protocol.py,server.py,backends/}` (Python),
`documentation/{PROJECT,PRD,DESIGN,AGENT,ROADMAP}.md` (specs, Indonesian).

Protocol: v1 input packet, 13 bytes @60 Hz, UDP port 9876; `PLpg`
ping and `PLds` discovery probes as separate auxiliary messages
(details: `documentation/PROJECT.md` §5).

### Author : Brenanda Caesa Pamudya
### Email Maintainer : brenandapamudya178@gmail.com
