# PROJECT.md — PadLink (nama sementara)

Aplikasi Flutter yang mengubah HP menjadi gamepad untuk bermain game di laptop. HP mengirim state input lewat jaringan lokal (UDP), server kecil di laptop menerjemahkannya menjadi gamepad virtual.

## 1. Ringkasan

| Item | Isi |
|---|---|
| Tujuan | HP sebagai controller laptop (layout ala PlayStation) |
| Platform app | Flutter (target awal: Android, iOS menyusul) |
| Platform server | Linux (`uinput`/`evdev`) dan Windows (ViGEmBus + `vgamepad`) |
| Transport | UDP via WiFi bersama atau hotspot HP |
| Gaya UI | Neumorphism, landscape |
| Status | Perencanaan |

## 2. Arsitektur

```
[Flutter app di HP] --UDP (WiFi / hotspot)--> [Server di laptop] --> [Gamepad virtual] --> Game
```

Dua komponen:
1. **app/** — Flutter. Menampilkan kontrol, membaca multi-touch, mengirim paket input 60 kali per detik.
2. **server/** — Python. Menerima paket, memvalidasi, lalu memperbarui gamepad virtual.

## 3. Struktur Repo

```
padlink/
├─ app/                  # Flutter project
│  └─ lib/
│     ├─ main.dart
│     ├─ core/           # tema, konstanta, model InputState
│     ├─ network/        # UdpSender, packet encoder, discovery
│     ├─ ui/
│     │  ├─ controller_screen.dart
│     │  ├─ widgets/     # NeuButton, NeuJoystick, NeuDpad, ShoulderButton
│     │  └─ connect_screen.dart
│     └─ settings/       # IP, port, sensitivitas, haptic
├─ server/
│  ├─ server.py          # entry point
│  ├─ protocol.py        # decoder paket
│  ├─ backends/
│  │  ├─ linux_uinput.py
│  │  └─ windows_vgamepad.py
│  └─ requirements.txt
├─ documentation/
├─ PROJECT.md  PRD.md  DESIGN.md  AGENT.md
```

## 4. Tech Stack

**App (Flutter)**
- `dart:io` `RawDatagramSocket` untuk UDP
- `Listener` (pointer events) untuk multi-touch
- `CustomPainter` untuk joystick dan efek neumorphic
- `wakelock_plus` agar layar tidak mati
- `HapticFeedback` untuk getaran
- Opsional: `sensors_plus` (gyro), `shared_preferences` (simpan IP dan setting)

**Server (Python 3.10+)**
- `asyncio` + `asyncio.DatagramProtocol`
- Linux: `python-evdev` (perlu akses `/dev/uinput`)
- Windows: `vgamepad` + driver ViGEmBus

## 5. Protokol Paket (v1)

Satu paket berisi seluruh state, dikirim 60 Hz. Little-endian, 13 byte.

| Offset | Ukuran | Field | Keterangan |
|---|---|---|---|
| 0 | 2 | magic | `0x50 0x4C` ("PL") |
| 2 | 1 | version | `1` |
| 3 | 2 | seq | uint16, naik tiap paket, untuk membuang paket terlambat |
| 5 | 2 | buttons | bitmask uint16 (lihat bawah) |
| 7 | 1 | l2 | 0–255 (analog trigger) |
| 8 | 1 | r2 | 0–255 |
| 9 | 1 | lx | int8, -127..127 |
| 10 | 1 | ly | int8 |
| 11 | 1 | rx | int8 |
| 12 | 1 | ry | int8 |

**Bitmask buttons**

| Bit | Tombol | Bit | Tombol |
|---|---|---|---|
| 0 | Cross (X) | 8 | D-pad Up |
| 1 | Circle | 9 | D-pad Down |
| 2 | Square | 10 | D-pad Left |
| 3 | Triangle | 11 | D-pad Right |
| 4 | L1 | 12 | Options/Start |
| 5 | R1 | 13 | Share/Select |
| 6 | L3 (tekan stick kiri) | 14 | PS/Home |
| 7 | R3 (tekan stick kanan) | 15 | cadangan |

Port default: **UDP 9876**.

## 6. Keamanan dan Keandalan

- Server hanya menerima paket dengan magic dan version valid; paket lain dibuang.
- **Failsafe:** jika tidak ada paket selama 500 ms, server melepas semua tombol dan mengembalikan stick ke tengah (mencegah tombol "nyangkut").
- Server hanya mendengarkan di jaringan lokal; jangan buka port ke internet.
- Opsional tahap lanjut: PIN pairing sederhana agar perangkat lain di WiFi yang sama tidak bisa mengirim input.

## 7. Roadmap

1. **M0 — Proof of concept:** server menerima UDP dan menekan satu tombol virtual; app Flutter dengan satu tombol.
2. **M1 — Layout lengkap:** joystick, D-pad, face buttons, L1/L2/R1/R2, multi-touch benar.
3. **M2 — Neumorphism + polish:** tema, state pressed, haptic, layar connect.
4. **M3 — Kenyamanan:** auto-discovery (UDP broadcast/QR), simpan setting, indikator latency.
5. **M4 — Lanjutan (opsional):** gyro, kustomisasi layout, Bluetooth HID (Android), dukungan iOS.

## 8. Risiko

| Risiko | Mitigasi |
|---|---|
| WiFi dengan client isolation (kampus/kafe) | Rekomendasikan hotspot HP; tampilkan petunjuk troubleshooting |
| Firewall memblokir UDP | Dokumentasikan aturan firewall; cek di layar connect |
| Latency terasa | Kirim state, bukan event; 60 Hz; hindari kerja berat di thread UI |
| Tidak ada feedback fisik tombol | Haptic ringan, efek pressed yang jelas |
| Game hanya mengenali XInput | Backend Windows meniru Xbox 360; Linux perlu mapping yang sesuai |
