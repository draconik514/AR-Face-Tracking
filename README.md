# AR Face Tracking 🎭

Aplikasi Augmented Reality berbasis deteksi wajah real-time menggunakan Flutter dan Google ML Kit. Aplikasi ini dapat mendeteksi wajah melalui kamera dan menampilkan filter AR seperti kacamata, masker, mahkota, kumis, dan telinga kucing secara real-time.

## ✨ Fitur

- 🎭 **5 Filter AR** — Kacamata, Masker, Mahkota, Kumis, Telinga Kucing
- 📍 **Posisi Filter Akurat** — menggunakan Face Landmark Detection (titik mata, hidung, mulut)
- 😄 **Deteksi Senyum** — notifikasi otomatis saat tersenyum
- 🔄 **Switch Kamera** — kamera depan ↔ belakang
- 📸 **Screenshot** — simpan hasil foto ke galeri HP
- 💾 **Riwayat Sesi** — data tersimpan ke cloud database (Supabase)

## 🛠️ Teknologi

| Teknologi | Versi | Fungsi |
|-----------|-------|--------|
| Flutter | 3.x | Framework utama |
| Google ML Kit Face Detection | 0.11.x | Deteksi wajah & landmark |
| Camera | 0.11.x | Akses kamera HP |
| Supabase Flutter | 2.x | Cloud database |
| Gal | 1.x | Simpan foto ke galeri |

## 📋 Prasyarat

Sebelum menjalankan aplikasi, pastikan sudah terinstall:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi 3.0+
- [Android Studio](https://developer.android.com/studio) atau VS Code
- Android SDK (API level 21+)
- HP Android yang support kamera (untuk testing)

## 🚀 Cara Install & Jalankan

### 1. Clone Repository

```bash
git clone https://github.com/draconik514/AR-Face-Tracking.git
cd AR-Face-Tracking
```

### 2. Install Dependencies

```bash
flutter pub get
```

> ✅ **Database Supabase sudah terkonfigurasi** — tidak perlu setup Supabase baru. Credentials sudah tersedia di `lib/main.dart`.

### 3. Jalankan Aplikasi

Sambungkan HP Android via USB dengan USB Debugging aktif, lalu:

```bash
flutter run
```

Atau untuk build APK:

```bash
flutter build apk --release
```

APK akan tersimpan di `build/app/outputs/flutter-apk/app-release.apk`

## 📱 Cara Aktifkan USB Debugging di HP

1. Buka **Settings → About Phone**
2. Tap **Build Number** sebanyak 7 kali
3. Buka **Settings → Developer Options**
4. Aktifkan **USB Debugging**
5. Sambungkan HP ke PC via kabel USB data
6. Tap **Allow** pada popup di HP

## 📁 Struktur Project

```
lib/
├── main.dart                  # Entry point & Supabase init
├── models/
│   └── mask_model.dart        # Model data sesi AR
├── screens/
│   ├── ar_screen.dart         # Layar utama AR + kamera
│   └── history_screen.dart    # Layar riwayat sesi
├── services/
│   └── supabase_service.dart  # Service koneksi Supabase
└── widgets/
    └── face_filter_painter.dart  # CustomPainter untuk filter AR
```

## 🎮 Cara Pakai Aplikasi

1. Buka aplikasi → izinkan akses kamera
2. Arahkan kamera ke wajah
3. Pilih filter di bagian bawah layar (kacamata, masker, dll)
4. Tap 📸 **Screenshot** untuk foto ke galeri
5. Tap 💾 **Simpan Session** untuk simpan ke database
6. Tap ikon 🔄 di AppBar untuk switch kamera depan/belakang
7. Tap ikon 📋 History untuk lihat riwayat sesi

## ⚠️ Catatan

- Aplikasi membutuhkan kamera untuk berfungsi
- Pastikan pencahayaan cukup agar wajah terdeteksi dengan baik
- Filter menggunakan Face Landmark, sehingga posisi lebih akurat saat wajah menghadap lurus ke kamera

## 📄 Lisensi

Project ini dibuat untuk keperluan tugas mata kuliah **Design AR/VR**.
