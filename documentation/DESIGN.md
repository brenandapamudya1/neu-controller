# DESIGN.md — Desain UI/UX

Gaya: **Neumorphism** (soft UI), orientasi **landscape**.

## 1. Layout Controller

```
┌──────────────────────────────────────────────────────────────┐
│ [L2]  [L1]                                      [R1]  [R2]   │
│                                                              │
│   ▲                    [Share] [Home] [Options]       △      │
│ ◄   ►  (D-pad)                                   □       ○   │
│   ▼                                                  ✕       │
│                                                              │
│            ◉ Stick kiri                    ◉ Stick kanan     │
│                                                              │
│  ● Terhubung · 12 ms                                  ⚙      │
└──────────────────────────────────────────────────────────────┘
```

- **Pojok kiri atas:** L2 (atas/luar), L1 (di bawahnya).
- **Pojok kanan atas:** R2, R1 (mirror).
- **Kiri tengah:** D-pad. **Kiri bawah:** joystick kiri.
- **Kanan tengah:** tombol aksi berbentuk diamond: △ atas, ○ kanan, ✕ bawah, □ kiri.
- **Kanan bawah:** joystick kanan.
- **Tengah atas:** Share, Home, Options (kecil, opsional).
- **Pojok bawah:** indikator koneksi (kiri) dan tombol pengaturan (kanan).

> Catatan: layout ala PlayStation (D-pad di atas stick kiri, stick kanan di bawah tombol aksi). Jika ingin ala Xbox (stick kiri di atas D-pad), cukup tukar posisi.

## 2. Design Tokens

### 2.1 Warna (tema terang)

| Token | Hex | Kegunaan |
|---|---|---|
| `bg` | `#E0E5EC` | Latar layar dan permukaan kontrol |
| `shadowLight` | `#FFFFFF` | Bayangan terang (kiri-atas) |
| `shadowDark` | `#A3B1C6` | Bayangan gelap (kanan-bawah) |
| `textMuted` | `#6B7A90` | Label, ikon netral |
| `accent` | `#5B8DEF` | Status aktif, stick saat ditekan |
| `ok` | `#2EBD85` | Terhubung |
| `warn` | `#F2A93B` | Latency tinggi |
| `error` | `#E5484D` | Terputus |

Warna glyph tombol aksi (agar mudah dibedakan di UI yang rendah kontras):

| Tombol | Warna |
|---|---|
| Triangle | `#2EBD85` |
| Circle | `#E5484D` |
| Cross | `#5B8DEF` |
| Square | `#D96FB0` |

### 2.2 Tema gelap (opsional)

| Token | Hex |
|---|---|
| `bg` | `#292D32` |
| `shadowLight` | `#33383E` |
| `shadowDark` | `#1F2226` |

### 2.3 Bayangan

| Kondisi | Konfigurasi |
|---|---|
| Raised (normal) | `shadowDark` offset (+6, +6), blur 12; `shadowLight` offset (-6, -6), blur 12 |
| Pressed (inset) | bayangan terbalik di dalam bentuk; permukaan sedikit lebih gelap |
| Bentuk kecil (tombol bahu/tengah) | offset 4, blur 8 |

Flutter tidak punya inset `BoxShadow` bawaan. Opsi: (a) paket seperti `flutter_inset_shadow`, atau (b) `CustomPainter` dengan gradien radial/linear untuk mensimulasikan cekungan. Pilih (b) jika ingin tanpa dependensi.

### 2.3 Bentuk dan ukuran

| Elemen | Bentuk | Ukuran (dp) |
|---|---|---|
| Tombol aksi | Lingkaran | 56–64 |
| D-pad | Plus dengan sudut membulat, 4 segmen | 150 total |
| Joystick (basis) | Lingkaran cekung | 130–150 |
| Joystick (knob) | Lingkaran menonjol | 60–70 |
| L1/R1 | Pil/rounded rect | 80 × 36 |
| L2/R2 | Pil/rounded rect | 80 × 44 |
| Tombol tengah | Pil kecil | 48 × 24 |

Area sentuh minimal **48 dp**, walaupun tampilan visual lebih kecil.

## 3. Perilaku Interaksi

| Elemen | Perilaku |
|---|---|
| Tombol | Down → status pressed + haptic ringan; Up → kembali raised |
| D-pad | Satu pointer dapat berpindah antar segmen; diagonal = dua arah aktif |
| Joystick | Basis cekung; knob mengikuti jari, dibatasi radius; kembali ke tengah saat dilepas; deadzone 8% |
| Joystick floating (opsional) | Basis muncul di titik sentuh pertama dalam zona stick |
| L2/R2 | Mode on/off di v1; mode analog (geser vertikal) di versi berikutnya |
| Multi-touch | Tiap kontrol melacak `pointer id` sendiri; tidak saling mengganggu |

## 4. Animasi

- Transisi raised → pressed: **60–80 ms**, kurva `easeOut`.
- Knob kembali ke tengah: **120 ms**, `easeOutBack` (ringan).
- Hindari animasi panjang; prioritas pada responsivitas.

## 5. Layar Lain

### 5.1 Connect
- Latar `bg`, kartu neumorphic berisi: field IP, field port (default 9876), tombol **Connect**.
- Daftar server hasil discovery (P1).
- Teks bantuan singkat: "Pastikan HP dan laptop di jaringan yang sama atau gunakan hotspot HP."

### 5.2 Pengaturan (overlay)
- Haptic, deadzone, sensitivitas, tema terang/gelap, tampilkan ping.
- Tombol "Putus koneksi".

### 5.3 Indikator Koneksi
- Titik berwarna + teks latency: hijau (<30 ms), kuning (30–80 ms), merah (terputus).

## 6. Aksesibilitas dan Keterbacaan

Neumorphism cenderung rendah kontras, jadi:
- Glyph tombol memakai warna jelas (lihat 2.1), bukan hanya bayangan.
- Status pressed harus terlihat tegas (cekungan + perubahan warna glyph).
- Label teks (L1, R2, dst.) memakai `textMuted` dengan ukuran ≥ 12 sp.
- Jangan mengandalkan warna saja untuk status koneksi; sertakan teks.

## 7. Aset

- Ikon glyph △ ○ ✕ □ digambar dengan `CustomPainter` (vektor), bukan gambar bitmap.
- Font: sistem atau satu font sans-serif (mis. Inter/Poppins) untuk label.
- Tanpa aset gambar berat agar build ringan.

## 8. Widget yang Perlu Dibuat

| Widget | Tanggung jawab |
|---|---|
| `NeuSurface` | Container dasar dengan bayangan raised/pressed |
| `NeuButton` | Tombol bulat dengan glyph; callback down/up |
| `NeuDpad` | Empat segmen arah dengan deteksi geser |
| `NeuJoystick` | Basis + knob, menghasilkan `Offset(-1..1)` |
| `ShoulderButton` | L1/L2/R1/R2 |
| `StatusPill` | Indikator koneksi dan latency |
