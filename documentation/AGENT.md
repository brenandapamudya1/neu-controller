# AGENT.md — Panduan untuk AI Coding Agent

Dokumen ini berisi aturan kerja bagi agent (Claude Code, Antigravity, Cursor, dll.) yang mengerjakan repo ini. Baca bersama `PROJECT.md`, `PRD.md`, dan `DESIGN.md` sebelum mengubah kode.

## 1. Konteks Singkat

PadLink: app Flutter (HP) yang mengirim state gamepad lewat UDP ke server Python di laptop, yang membuat gamepad virtual. Landscape, UI neumorphism.

Sumber kebenaran:
- Protokol paket → `PROJECT.md` bagian 5
- Fitur dan prioritas → `PRD.md`
- Tampilan, token warna, ukuran → `DESIGN.md`

Jika kode dan dokumen bertentangan, jangan menebak: perbarui dokumen bersama kode, dan sebutkan perubahannya di ringkasan.

## 2. Aturan Umum

1. Kerjakan **satu milestone/tugas kecil per langkah**; jangan membangun semua fitur sekaligus.
2. Jalankan analisis dan test sebelum menyatakan tugas selesai.
3. Jangan menambah dependensi baru tanpa alasan; sebutkan alasannya.
4. Jangan mengubah format paket tanpa menaikkan `version` dan memperbarui `PROJECT.md`, encoder (app), dan decoder (server) bersamaan.
5. Jangan menyimpan data sensitif atau kredensial di repo.
6. Komentar kode dalam bahasa Inggris; dokumen boleh bahasa Indonesia.
7. Bila ada keputusan yang ambigu (mis. layout, perilaku tombol), pilih opsi paling sederhana yang sesuai dokumen dan catat asumsinya.

## 3. Perintah Penting

**App (Flutter)**
```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run            # perangkat/emulator Android
dart format lib test
```

**Server (Python)**
```bash
cd server
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python server.py --port 9876
pytest                 # jika ada test
```

Linux: server butuh akses `/dev/uinput` (mis. aturan udev atau grup `input`). Windows: pasang ViGEmBus terlebih dahulu.

## 4. Konvensi Kode

### Flutter / Dart
- Ikuti `flutter_lints`; `flutter analyze` harus bersih.
- State sederhana: `ValueNotifier`/`ChangeNotifier`. Jangan menambah state management berat tanpa kebutuhan.
- Satu model tunggal `InputState` (buttons bitmask, l2, r2, lx, ly, rx, ry) sebagai satu-satunya sumber data kontrol.
- Widget kontrol **tidak** boleh mengirim jaringan sendiri; mereka hanya memperbarui `InputState`.
- `UdpSender` membaca `InputState` dengan timer tetap (60 Hz) dan mengirim satu paket. Jangan kirim per event.
- Gunakan `Listener` (`onPointerDown/Move/Up/Cancel`) dan lacak `pointer id` per kontrol; hindari `onTap`/`GestureDetector` untuk kontrol utama karena merusak multi-touch.
- Hindari `setState` pada widget besar di setiap pointer move; bungkus bagian yang berubah dengan `ValueListenableBuilder`/`RepaintBoundary`.
- Nilai warna, ukuran, dan bayangan diambil dari satu file tema (`core/theme.dart`) sesuai `DESIGN.md`; tidak ada angka ajaib tersebar.
- Kunci orientasi landscape dan aktifkan wakelock di layar controller; lepaskan saat keluar.

### Python
- Python 3.10+, type hints, `black` + `ruff` bila tersedia.
- Decoder paket murni (tanpa efek samping) di `protocol.py` agar mudah dites.
- Backend platform di belakang satu antarmuka (`update(state)`, `reset()`, `close()`); `server.py` tidak boleh tahu detail `evdev`/`vgamepad`.
- Wajib ada failsafe: tidak ada paket 500 ms → `reset()`.
- Validasi: magic, version, panjang; abaikan paket `seq` lebih lama (hitung wrap-around uint16).

## 5. Pengujian

| Area | Minimal yang dites |
|---|---|
| Encoder/decoder paket | Round-trip semua field, nilai batas (-127, 127, 0, 255), bitmask tiap tombol |
| Server | Paket tidak valid dibuang; `seq` lama dibuang; failsafe memicu reset |
| Widget Flutter | Joystick: keluaran -1..1 dan kembali ke 0 saat dilepas; multi-touch dua kontrol bersamaan |
| Manual | Uji dengan game atau alat uji gamepad (mis. `jstest`/`evtest` di Linux, "Set up USB game controllers" di Windows) |

## 6. Urutan Kerja yang Disarankan

1. `server/protocol.py` + test.
2. Backend gamepad virtual (Linux atau Windows) + `server.py` yang menekan tombol dari paket.
3. `app/` minimal: satu tombol → UDP → server menekan tombol (M0).
4. Model `InputState` + `UdpSender` 60 Hz.
5. Widget: `NeuSurface`, `NeuButton`, `NeuJoystick`, `NeuDpad`, `ShoulderButton`.
6. Layar controller sesuai layout `DESIGN.md` (M1), lalu tema dan haptic (M2).
7. Connect screen, simpan IP, ping, discovery (M3).

## 7. Yang Tidak Boleh Dilakukan

- Jangan membuka port server ke internet atau menambah akses jaringan selain UDP lokal.
- Jangan menghapus failsafe atau validasi paket demi "kinerja".
- Jangan mengganti arsitektur (mis. ke WebSocket atau Bluetooth) tanpa persetujuan eksplisit; Bluetooth adalah fitur P2 yang terpisah sebagai lapisan transport.
- Jangan menggunakan gambar bitmap untuk glyph/tombol; gunakan `CustomPainter`.
- Jangan mengerjakan fitur di luar milestone aktif.

## 8. Format Laporan Setelah Tugas

Akhiri setiap tugas dengan ringkasan singkat:
1. Apa yang diubah (file dan alasan).
2. Cara menjalankan/mengujinya.
3. Hasil `flutter analyze`/test.
4. Asumsi atau pertanyaan terbuka.
