# PadLink — HP sebagai gamepad laptop

Aplikasi Flutter yang mengubah HP menjadi gamepad untuk game di laptop.
HP mengirim state input via UDP (60 Hz), server Python di laptop
menerjemahkannya menjadi gamepad virtual.

```
[HP: Flutter app] --UDP 9876--> [Laptop: server.py] --> [gamepad virtual] --> Game
```

> Status: v1 fitur selesai di Linux (M0–M3). Backend Windows
> (`ViGEmBus`) dan M4 (gyro, Bluetooth HID, iOS) belum diimplementasikan.

## Setup cepat (< 2 menit)

Butuh: HP Android + laptop Linux di jaringan yang sama
(atau hotspot HP — direkomendasikan), dan server di bawah berjalan
di laptop. Tanpa server, app tidak bisa apa-apa.

**1. Laptop — jalankan server:**
```bash
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python server.py --port 9876
# catat baris "connect the app to: <IP>:9876"
```

Izin sekali saja di Linux (akses `/dev/uinput`):
```bash
sudo usermod -aG input $USER   # lalu logout/login lagi
sudo ufw allow 9876/udp        # jika firewall aktif
```

**2. HP — jalankan app:**
```bash
cd app
flutter pub get
flutter run            # pilih perangkat Android (USB debugging aktif)
```

**3. Di app:** layar Connect → daftar "Nearby servers" → tap nama
laptop (atau isi IP manual) → Connect → main. Status hijau <30 ms
artinya link sehat.

Tanpa build dari source, langkah HP diganti: install APK hasil
`flutter build apk` lalu ikuti langkah 3.

## Verifikasi gamepad virtual

```bash
sudo evtest            # pilih device "PadLink", tekan tombol di HP
# atau: jstest /dev/input/js0
```

Checklist lulus v1 (PRD §7):
- [ ] Game mengenali perangkat virtual sebagai gamepad.
- [ ] Dua tombol + satu stick bersamaan tanpa saling memutus.
- [ ] Matikan WiFi/app → semua input netral ≤ 1 detik (failsafe).
- [ ] Semua kontrol (stick, D-pad, aksi, bahu) berfungsi di Android.
- [ ] Setup hotspot + IP manual berhasil dari nol.

## Troubleshooting

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| Daftar server kosong | Broadcast diblokir / WiFi isolasi client (kampus/kafe) | Isi IP manual dari log server; atau pakai hotspot HP |
| Connect tapi pill merah terus | Firewall laptop blok UDP | `sudo ufw allow 9876/udp`; cek `server.py --dry-run` menerima ping |
| `Cannot open /dev/uinput` | Grup `input` / udev | `usermod -aG input`, relogin; darurat: `--dry-run` untuk tes jaringan saja |
| Tombol "nyangkut" | Paket hilang saat putus | Failsafe 500 ms me-reset otomatis; jangan dimatikan. Laporkan bila terjadi |
| Latency kuning/merah | WiFi ramai, jarak jauh | Dekatkan perangkat, pakai hotspot HP, tutup download besar |
| Windows | Backend belum ada | v1 = Linux dulu; Windows butuh `backends/windows_vgamepad.py` + driver ViGEmBus |

## Untuk pengembang

```bash
cd app && flutter analyze && flutter test        # 57+ test widget
cd server && source .venv/bin/activate \
  && PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python -m pytest tests/ -q
python server.py --dry-run --port 9876           # tes jaringan tanpa hardware
```

Struktur: `app/lib/{core,network,ui,settings}` (Flutter),
`server/{protocol.py,server.py,backends/}` (Python),
`documentation/{PROJECT,PRD,DESIGN,AGENT,ROADMAP}.md` (spesifikasi).

Protokol: paket input v1 13 byte @60 Hz, port UDP 9876; probe
ping `PLpg` dan discovery `PLds` sebagai pesan bantu terpisah
(detail: `documentation/PROJECT.md` §5).

### Author : Brenanda Caesa Pamudya
### Email Maintainer : brenandapamudya178@gmail.com
