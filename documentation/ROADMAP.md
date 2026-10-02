# ROADMAP.md — PadLink (NeuController)

Catatan resmi tahapan kerja. Sumber kebenaran tetap:
- Protokol paket → `PROJECT.md` bagian 5
- Fitur/prioritas → `PRD.md`
- Tampilan/token → `DESIGN.md`
- Aturan agent → `AGENT.md`

Status repo: `app/` + `server/` dirintis dari nol (sebelumnya hanya `documentation/`).

## 0. Arsitektur singkat

```
[Flutter HP] --UDP 13 byte @60Hz, port 9876--> [Python laptop] --> [gamepad virtual] --> Game
```

App tidak independen: laptop wajib menjalankan `server/server.py`.
Tanpa server, paket UDP tidak ada yang menerjemahkan ke OS.
Opsi independen (Bluetooth HID) adalah P2, di luar v1.

Protokol v1: `magic 0x50 0x4C`, `version 1`, `seq u16`, `buttons u16`,
`l2/r2 u8 0-255`, `lx/ly/rx/ry i8 -127..127`. Failsafe 500 ms → `reset()`.

## M0 — Proof of Concept (SELESAI, Linux)

Tujuan: 1 tombol HP → UDP → tombol virtual laptop. Bukti jaringan + failsafe jalan.

- [x] `server/protocol.py` — encode/decode murni, `is_seq_newer()` handle wrap u16
- [x] `server/backends/__init__.py` — interface `update/reset/close` + `LoggingBackend`
- [x] `server/backends/linux_uinput.py` — evdev `BTN_SOUTH/EAST/NORTH/WEST, TL/TR, THUMBL/BR, DPAD_*, START/SELECT/MODE`, stick `ABS_X/Y/RX/RY -127..127`, trigger `ABS_Z/RZ 0..255`
- [x] `server/server.py` — `asyncio.DatagramProtocol`, buang magic/version/panjang invalid + `seq` lama, log `client connected`, failsafe loop 100 ms
- [x] `server/requirements.txt` — `evdev`, `pytest`
- [x] `server/tests/test_protocol.py` — 7 test (round-trip, boundary, bitmask 0-14, invalid, seq basic + wrap, server drop old/invalid)
- [x] `app/` minimal — `InputState` tunggal, `packet.dart` encoder, `UdpSender` 60 Hz, `main.dart` 1 tombol X via `Listener`

Verifikasi 2026-10-02:
- `py_compile`: OK
- `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python -m pytest tests/test_protocol.py`: **7 passed**
- `python server.py --dry-run --port 9877` + kirim 2 paket: `client connected`, `failsafe: no packet for 0.53s, resetting inputs` — sesuai target
- `flutter analyze/test`: awalnya belum jalan (SDK belum ada), 2026-10-02 terverifikasi setelah install Flutter 3.47.6: `analyze: No issues found`, `flutter test: 3 passed` (theme + NeuSurface)

Catatan env: image ini ada ROS Humble system-wide yang merusak `pytest` global (plugin `launch_testing`/`anyio`). Bukan dependensi project. Selalu pakai `server/.venv` + `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1`.

## M1 — Layout lengkap (BERJALAN, slice M1a selesai)

- [x] M1a fondasi: `core/theme.dart` (token DESIGN.md §2-4) + `NeuSurface` raised/pressed via `CustomPainter` + test widget
- [x] M1b buttons: `ActionGlyph` vektor, `NeuPressable` (pointer-id per kontrol), `NeuButton` aksi + `ShoulderButton` L1/L2/R1/R2 on/off + 5 widget test (down/up/cancel, multi-touch 2 tombol)
- [x] M1c joystick: `NeuJoystick` basis cekung + knob, deadzone 8%, output -1..1 + clamp, balik 120 ms easeOutBack + 4 widget test (range, deadzone, clamp, multi-touch stick+tombol)
- [x] M1d layout: `NeuDpad` geser antar-segmen + diagonal, `CenterButton` Share/Home/Options, `ControllerScreen` landscape full terhubung ke `ControllerState` + `UdpSender`, `main.dart` baru + 8 widget test (dpad 3, screen 5)
- [ ] `InputState` penuh di app + `UdpSender` stabil 60 Hz tanpa jank
- [ ] Widget: `NeuJoystick` (output -1..1, deadzone 8%, kembali 0 saat lepas), `NeuDpad` (geser antar segmen, diagonal = 2 arah), `NeuButton` aksi, `ShoulderButton` L1/L2/R1/R2 (v1 boleh on/off)
- [ ] Layar controller landscape sesuai `DESIGN.md` §1 (D-pad kiri-atas, stick kiri-bawah, aksi kanan-tengah, stick kanan-bawah, L2/L1 kiri-atas, R2/R1 kanan-atas)
- [ ] Multi-touch: tiap kontrol tracking `pointer id` sendiri, `ValueListenableBuilder`/`RepaintBoundary`, tanpa `setState` besar per move
- [ ] Lulus: 2 tombol + 1 stick bersamaan tanpa putus, semua F-01..F-07 di Android

## M2 — Neumorphism + polish (BERJALAN, slice M2a selesai)

- [x] M2a flow + persist: `AppSettings` (IP/port, haptic, dark, deadzone via `shared_preferences` — alasan: tanpa key-value bawaan), `ConnectScreen` kartu neumorphic + validasi + teks hotspot, `ControllerScreen` auto-connect + Disconnect, `main.dart` Connect → Controller (PRD §6)
- [x] M2b device + wiring: `wakelock_plus` (alasan: tanpa API bawaan; PRD F-20) on/off di controller, haptic + deadzone settings diteruskan ke semua kontrol live via `ListenableBuilder` + 2 widget test (propagasi, deadzone lebar)
- [x] M2c tema + pengaturan: `NeuPalette` light/dark + `NeuTheme` (fallback terang), semua widget baca palet aktif, `SettingsSheet` (haptic, dark, deadzone, putus) + gear di controller, `main.dart` ikut `ThemeData` brightness + 10 test (tema 4, sheet 5, gear 1)
- [ ] `core/theme.dart` — token `DESIGN.md` §2 (bg, shadowLight/Dark, textMuted, accent, ok/warn/error, warna glyph Triangle/Circle/Cross/Square), tanpa angka ajaib
- [ ] `NeuSurface` raised/pressed (60-80 ms easeOut, knob balik 120 ms easeOutBack), efek inset via `CustomPainter` (tanpa `flutter_inset_shadow` bila bisa)
- [ ] Haptic ringan + wakelock landscape di controller, lepas saat keluar
- [ ] Layar Connect: field IP + port default 9876 + tombol Connect + teks hotspot, simpan IP terakhir

## M3 — Kenyamanan (SELESAI)

- [x] M3a ping: probe `PLpg` + nonce u64 echo server (tanpa ubah v1, tanpa version bump), `PingService` 1 Hz + timeout 1.5 s, `StatusPill` hijau <30 / kuning + teks / merah putus, kabel ke controller, log IP LAN di console + 8 test (py 4, dart 4+3+1)
- [x] M3b discovery: query broadcast `PLds` + reply unicast (port + hostname), `DiscoveryService` + daftar server di Connect (tap mengisi IP/port, auto-scan saat buka), fallback IP manual + 9 test (py 5, dart 5+2)
- [ ] Discovery UDP broadcast/QR + daftar server, simpan setting (`shared_preferences`)
- [x] M3c docs: `README.md` setup <2 menit + izin uinput/firewall + troubleshooting + checklist PRD §7 (jujur: Windows backend belum ada)
- [ ] Target: setup <2 menit, rata-rata ping tercatat, nol tombol nyangkut (cabut WiFi → netral ≤1 detik)

## M4 — Lanjutan (opsional, P2)

- L3/R3 tekan stick, gyro (`sensors_plus`), kustom posisi/ukuran, PIN pairing, Bluetooth HID Android, iOS, macOS. Jangan dikerjakan sebelum M1-M3 stabil tanpa persetujuan eksplisit.

## Perintah penting

App:
```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

Server:
```bash
cd server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python -m pytest tests/test_protocol.py -v
python server.py --dry-run --port 9876   # tanpa hardware
python server.py --port 9876             # butuh /dev/uinput (grup input / udev)
```

## Risiko

| Risiko | Mitigasi |
|---|---|
| WiFi client isolation kampus/kafe | Hotspot HP + petunjuk di Connect |
| Firewall blok UDP | Dokumentasi aturan, cek di Connect |
| Latency | Full-state 60 Hz, hindari kerja berat di UI thread |
| Tombol nyangkut | Failsafe 500 ms, jangan dihapus demi kinerja |
| Game hanya XInput | Windows tiru Xbox 360, Linux mapping sesuai |

## Log

- 2026-10-02: M0 Linux selesai (server + test + app 1 tombol).
- 2026-10-02: M1a selesai (theme + NeuSurface, tanpa dependensi baru).
- 2026-10-02: M1b selesai (buttons, `analyze` bersih, `flutter test` 8/8).
- 2026-10-02: M1c selesai (joystick, `analyze` bersih, `flutter test` 12/12).
- 2026-10-02: M1d selesai (dpad + layout, `analyze` bersih, `flutter test` 22/22). M1 TUNTAS.
- 2026-10-02: M2a selesai (settings + connect flow, dep baru `shared_preferences` beralasan, `analyze` bersih, `flutter test` 30/30).
- 2026-10-02: M2b selesai (wakelock + wiring, dep baru `wakelock_plus` beralasan, `analyze` bersih, `flutter test` 32/32).
- 2026-10-02: M2c selesai (tema gelap + sheet, tanpa dep baru, `analyze` bersih, `flutter test` 43/43). M2 TUNTAS.
- 2026-10-02: M3a selesai (ping + pill, `pytest` 11/11, `analyze` bersih, `flutter test` 50/50).
- 2026-10-02: M3b selesai (discovery, `pytest` 16/16, `analyze` bersih, `flutter test` 57/57).
- 2026-10-02: M3c selesai (README + troubleshooting, tanpa kode). v1 FITUR LENGKAP di Linux; sisa: uji fisik HP→laptop, backend Windows, M4 opsional.
- 2026-10-02: CI `.github/workflows/build-apk.yml` (analyze+test+APK tiap push/PR, Release + APK tiap tag `v*`, Flutter 3.47.6). README dapat section download.
