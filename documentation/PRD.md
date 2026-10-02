# PRD.md — Product Requirements Document

**Produk:** PadLink (nama sementara)
**Versi dokumen:** 0.1
**Status:** Draft

## 1. Latar Belakang

Gamepad fisik tidak selalu tersedia. HP hampir selalu dibawa, punya layar sentuh dan WiFi. Produk ini membuat HP berfungsi sebagai gamepad untuk game di laptop tanpa membeli perangkat tambahan.

## 2. Tujuan dan Non-Tujuan

**Tujuan**
- Mengubah HP menjadi gamepad dengan layout ala PlayStation.
- Dikenali game di laptop sebagai gamepad sungguhan.
- Setup cepat (di bawah 2 menit dari nol).
- Latency cukup rendah untuk game santai hingga menengah.

**Non-tujuan (v1)**
- Streaming layar game ke HP.
- Mengontrol konsol PlayStation/Xbox secara langsung.
- Dukungan macOS.
- Kontrol lewat internet (di luar jaringan lokal).

## 3. Pengguna dan Skenario

| Persona | Kebutuhan |
|---|---|
| Pemain kasual | Main game PC/emulator bersama teman tanpa gamepad tambahan |
| Mahasiswa/pengembang | Controller murah untuk eksperimen, demo, atau proyek lain |

**Skenario utama:** Pengguna menyalakan hotspot HP, menyambungkan laptop, menjalankan server, membuka app, memasukkan IP laptop, lalu bermain.

## 4. Kebutuhan Fungsional

Prioritas: **P0** wajib v1, **P1** sebaiknya ada, **P2** nanti.

### 4.1 Kontrol

| ID | Kebutuhan | Prio |
|---|---|---|
| F-01 | Layar controller landscape penuh | P0 |
| F-02 | Joystick analog kiri dan kanan (axis -127..127) | P0 |
| F-03 | D-pad (arah) di sisi kiri | P0 |
| F-04 | Tombol aksi kanan: Triangle, Circle, Cross, Square | P0 |
| F-05 | Tombol bahu kiri: L1 dan L2; kanan: R1 dan R2 | P0 |
| F-06 | L2/R2 mengirim nilai analog 0–255 (atau minimal on/off) | P0 |
| F-07 | Multi-touch: banyak kontrol dapat aktif bersamaan | P0 |
| F-08 | Tombol tengah: Options, Share, Home | P1 |
| F-09 | Tekan stick untuk L3/R3 | P2 |
| F-10 | Gyro sebagai input tambahan | P2 |

### 4.2 Koneksi

| ID | Kebutuhan | Prio |
|---|---|---|
| F-11 | Input IP dan port server secara manual | P0 |
| F-12 | Bekerja lewat hotspot HP dan WiFi bersama | P0 |
| F-13 | Indikator status koneksi dan latency (ping) | P1 |
| F-14 | Auto-discovery server (UDP broadcast atau QR) | P1 |
| F-15 | Simpan IP terakhir | P1 |
| F-16 | PIN pairing | P2 |
| F-17 | Bluetooth HID (Android) | P2 |

### 4.3 Server

| ID | Kebutuhan | Prio |
|---|---|---|
| S-01 | Menerima paket UDP sesuai protokol v1 | P0 |
| S-02 | Membuat gamepad virtual (Linux uinput, Windows ViGEm) | P0 |
| S-03 | Failsafe: reset input jika tidak ada paket 500 ms | P0 |
| S-04 | Membuang paket dengan `seq` lama atau tidak valid | P0 |
| S-05 | Log sederhana (client terhubung, error) | P1 |
| S-06 | Balas ping untuk pengukuran latency | P1 |

### 4.4 Pengaturan

| ID | Kebutuhan | Prio |
|---|---|---|
| F-18 | Haptic on/off | P1 |
| F-19 | Deadzone dan sensitivitas stick | P1 |
| F-20 | Layar tetap menyala selama sesi | P0 |
| F-21 | Kustomisasi posisi/ukuran kontrol | P2 |

## 5. Kebutuhan Non-Fungsional

| Aspek | Target |
|---|---|
| Latency end-to-end | Idealnya di bawah 30 ms di hotspot/WiFi bersih (diukur, bukan dijamin) |
| Laju kirim | 60 paket/detik, ukuran 13 byte |
| Frame rate UI | 60 fps, tanpa jank saat multi-touch |
| Stabilitas | Tidak ada tombol "nyangkut" saat koneksi putus |
| Konsumsi baterai | Layar menyala terus; sarankan HP di-charge untuk sesi panjang |
| Kompatibilitas | Android 8+ dahulu; iOS menyusul |

## 6. Alur Pengguna

1. Buka server di laptop → server menampilkan IP dan port.
2. Buka app → layar **Connect**: isi IP (atau pilih dari hasil discovery).
3. Tekan **Connect** → status berubah hijau.
4. Layar **Controller** terbuka (landscape, layar tetap menyala).
5. Bermain. Tombol Back/menu untuk keluar atau membuka pengaturan.

## 7. Kriteria Penerimaan (v1)

- [ ] Game yang mendukung XInput/gamepad generik mengenali perangkat virtual.
- [ ] Dua tombol aksi dan satu stick dapat dipakai bersamaan tanpa saling memutus.
- [ ] Mencabut koneksi (matikan WiFi/app) membuat semua input kembali netral dalam ≤ 1 detik.
- [ ] Semua kontrol pada F-01 sampai F-07 berfungsi di Android.
- [ ] Setup lewat hotspot HP dengan IP manual berhasil mengikuti README.

## 8. Metrik Keberhasilan

- Waktu setup pertama kali (target < 2 menit).
- Rata-rata ping pada hotspot (dicatat di app).
- Jumlah laporan "tombol nyangkut" (target nol).

## 9. Asumsi dan Pertanyaan Terbuka

- Tombol "analog kiri" diasumsikan sebagai **D-pad**, di samping joystick kiri.
- Tombol **Cross (X)** ditambahkan melengkapi Triangle, Circle, Square.
- OS laptop target: Linux dan Windows (server dibuat dengan backend terpisah).
- Apakah iOS masuk target v1 atau ditunda?
- Apakah perlu tampilan "mode kanan/kiri" untuk pengguna kidal?
