# NeuController — Phone as a Gamepad & Desktop Controller Manager

NeuController turns your Android smartphone into a low-latency virtual gamepad for Linux PCs and laptops. Controller inputs are streamed over UDP (60 Hz) in real-time and translated into a virtual game controller using Linux `uinput`. It includes a modern neumorphic Electron desktop manager for background server lifecycle control, network diagnostics, and real-time input visualization.

```
[Phone: Flutter App] --- UDP (Port 9876) ---> [Laptop: Electron / Python Server] ---> [Virtual Gamepad /dev/uinput] ---> Games
```

<div align="center">

### Download NeuController APK for Android

Get started right away by downloading the ready-to-use Android APK directly on your phone:

<br/>

<a href="https://github.com/brenandapamudya1/neu-controller/releases/latest/download/neu-controller.apk">
  <img src="https://img.shields.io/badge/Download_APK-Direct_Download_(Android)-007AFF?style=for-the-badge&logo=android&logoColor=white" height="48" alt="Direct Download APK for Android"/>
</a>
&nbsp;&nbsp;
<a href="https://github.com/brenandapamudya1/neu-controller/releases/latest">
  <img src="https://img.shields.io/badge/GitHub_Releases-View_All_Versions-238636?style=for-the-badge&logo=github&logoColor=white" height="48" alt="GitHub Releases"/>
</a>

<br/>
<br/>

**Direct Link:** [**Download neu-controller.apk**](https://github.com/brenandapamudya1/neu-controller/releases/latest/download/neu-controller.apk) (Instant download, no build tools required)

*Compatible with Android 8.0 (Oreo) and newer.*

</div>

---

## Preview

| Desktop Manager (Electron GUI) | Mobile Controller (Flutter App) |
|:---:|:---:|
| <img src="image/electron-preview.jpeg" alt="NeuController Desktop Preview" width="500"/> | <img src="image/controller-preview.jpeg" alt="NeuController Mobile Preview" width="500"/> |

---

## Quick Startup Guide

### 0. Linux Permission Setup (One-Time Setup)

To allow the server to create a virtual input device without requiring root permissions (`sudo`) on every launch, configure access to `/dev/uinput`:

```bash
# Add current user to the input group
sudo usermod -aG input $USER

# Grant write permissions to /dev/uinput (or configure a udev rule)
sudo chmod 660 /dev/uinput && sudo chgrp input /dev/uinput

# Allow UDP port in firewall if enabled
sudo ufw allow 9876/udp
```

> **Note:** After running `usermod`, log out and log back in for group membership changes to take effect.

---

### 1. Launch Server / Desktop Manager (Choose One)

#### Option A: Desktop Manager (Electron GUI) — Recommended
The desktop manager provides a neumorphic interface, automatically runs the Python server in the background, displays your local IP and port, features a real-time input visualizer, and supports minimizing to the system tray.

```bash
cd electron
npm install
npm start
```

#### Option B: Headless CLI Server (Terminal Only)
If you prefer running the server via command line without a GUI:

```bash
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python server.py --port 9876
```
*(Note: You can pass `--dry-run` to test network communication without creating a virtual hardware device).*

---

### 2. Launch Mobile App

#### Option 1: Direct APK Download (Recommended)
Download and install the APK directly on your Android phone without needing Flutter:
1. Tap [Direct Download neu-controller.apk](https://github.com/brenandapamudya1/neu-controller/releases/latest/download/neu-controller.apk) on your Android device (or view all versions on [GitHub Releases](https://github.com/brenandapamudya1/neu-controller/releases)).
2. Allow installation from unknown sources when prompted and install the app.
3. Open **Neu Controller**, select your laptop under **Nearby servers** (or enter the IP address manually), and tap **Connect**.

#### Option 2: Run from Source (Flutter SDK)
```bash
cd mobile
flutter pub get
flutter run
```

---

## Key Features

- **Ultra-Low Latency UDP**: 60 Hz input updates with real-time round-trip latency tracking (<30 ms on local Wi-Fi or phone hotspot).
- **Neumorphism Dark Theme**: Consistent soft-shadow aesthetic across both Android and Desktop applications.
- **Desktop Manager GUI**:
  - Built with Electron and Lucide icons.
  - Live controller visualizer (dynamic analog stick deflection and button highlights).
  - Background process management (automatic start, stop, and status monitoring of the Python backend).
  - Window controls with minimize-to-system-tray functionality.
- **Full Gamepad Emulation**: Dual analog sticks, D-pad, action buttons (Cross, Circle, Square, Triangle), shoulder bumpers (L1/R1), triggers (L2/R2), and Start/Select buttons.
- **Fail-Safe Mechanism**: Automatically resets all virtual controller inputs to neutral if connection drops for more than 500 ms to prevent stuck inputs.

---

## Verifying Virtual Gamepad on Linux

Verify that the system registers the virtual gamepad:

```bash
# Check input events using evtest
sudo evtest
# Select "NeuController" (or "PadLink") and press buttons on your phone to observe events

# Alternatively, test with jstest
jstest /dev/input/js0
```

---

## Troubleshooting

| Issue | Likely Cause | Solution |
|---|---|---|
| Server not found in mobile app | Wi-Fi client isolation (common on public/campus Wi-Fi) | Use phone hotspot to connect laptop and phone directly, or manually enter the IP displayed in the desktop app |
| Connection indicator remains red / ping timeout | Laptop firewall is blocking incoming UDP packets | Run `sudo ufw allow 9876/udp` |
| `Cannot open /dev/uinput: Permission denied` | User does not have read/write access to `/dev/uinput` | Run `sudo chmod 660 /dev/uinput && sudo chgrp input /dev/uinput` or add user to `input` group and re-login |
| Server crashes immediately without `--dry-run` | `/dev/uinput` permission issue or missing module | Configure uinput permissions as shown above, or run with `--dry-run` to test network only |
| Noticeable input delay or packet loss | 2.4 GHz Wi-Fi congestion or distance | Switch to 5 GHz Wi-Fi or tether laptop via phone Wi-Fi hotspot |

---

## Repository Structure

```
neu-controller/
├── electron/          # Desktop manager UI (Electron, Lucide icons, IPC)
├── mobile/            # Mobile gamepad app (Flutter, neumorphic UI, UDP client)
├── server/            # Virtual controller backend (Python, Linux uinput)
├── image/             # Screenshots and preview assets
└── documentation/     # Technical specifications and design documents
```

---

## Author & Maintainer
- **Author**: Brenanda Caesa Pamudya
- **Email**: brenandapamudya178@gmail.com
- **Repository**: [github.com/brenandapamudya1/neu-controller](https://github.com/brenandapamudya1/neu-controller)
