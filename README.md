# smarttrip

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# SmartTrip — Panduan Integrasi Backend

Dokumen ini dibuat untuk tim backend, berisi ringkasan kondisi aplikasi Flutter SmartTrip saat ini, pola data yang dipakai, dan bagian mana saja yang butuh dihubungkan ke API/backend.

## 1. Ringkasan Proyek

SmartTrip adalah aplikasi Flutter untuk wisata di Lampung, dengan fitur utama:
- Katalog & pencarian destinasi wisata
- Rekomendasi destinasi
- Prediksi kepadatan pengunjung
- Perencanaan itinerary (manual & berbasis AI)
- Peta lokasi
- Ulasan (review) destinasi
- Profil user & riwayat perjalanan
- Notifikasi

## 2. Status Saat Ini: Frontend-Only

**Penting untuk diketahui tim backend:** seluruh aplikasi saat ini berjalan **100% in-memory di sisi Flutter**. Belum ada satu pun panggilan API ke server sungguhan. Semua "penyimpanan data" (profil, destinasi favorit, itinerary, ulasan, notifikasi) hanya hidup selama aplikasi berjalan dan hilang saat aplikasi ditutup.

Layar login (`login_screen.dart`) dan registrasi (`register_screen.dart`) juga baru berupa UI — belum terhubung ke sistem autentikasi apa pun.

## 3. Tech Stack Frontend

| Package | Kegunaan |
|---|---|
| `flutter_svg` | Render ikon SVG |
| `flutter_map` + `latlong2` | Peta (bukan Google Maps — pakai flutter_map/OpenStreetMap-style) |
| `geolocator` | Ambil lokasi user (perlu izin lokasi) |
| `http` | Sudah terpasang, siap dipakai untuk panggilan API — belum digunakan aktif |
| `image_picker` | Ambil foto dari kamera/galeri (foto profil, foto ulasan) |

Permission Android yang sudah didaftarkan (`AndroidManifest.xml`): `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA`.

## 4. Pola Arsitektur Saat Ini

Alih-alih state management library (Provider/Bloc/Riverpod), project ini pakai pola **singleton service + `ValueNotifier`** bawaan Flutter sebagai *single source of truth* sementara. Contoh: `SavedItineraryService.instance`, `ProfileService.instance`.

Pola ini sengaja dipilih supaya nanti **tinggal isi method di dalam service dengan panggilan API**, tanpa perlu mengubah kode di layar (screen) yang memanggilnya — signature method tetap sama.

## 5. Service yang Perlu Dipetakan ke Backend

Setiap service di bawah ini merepresentasikan satu "domain data" yang kemungkinan besar butuh endpoint sendiri.

### `ProfileService`
Data profil user: `name`, `bio`, `username`, `birthDate`, `phone`, `email`, `photoPath`.
→ Butuh: endpoint get/update profil user, endpoint upload foto profil.

### `SavedDestinationsService`
Set `id` destinasi yang di-*favorite*/simpan user.
→ Butuh: endpoint get daftar favorit user, toggle favorit (add/remove).

### `SavedItineraryService`
Ini yang paling kompleks. Setiap itinerary berisi list per hari (`day`, `tripName`, `startDate`, `endDate`, `participants`, `vehicle`, `destination`, `startLocation`, `departureTime`, `destinations: [...]`), ditambah `itineraryId` yang dibuat otomatis saat pertama disimpan.

Poin desain penting yang perlu dipertahankan di backend:
- Status "selesai" (`dayCompleted`) disimpan **per hari**, bukan satu flag untuk seluruh itinerary. Satu itinerary multi-hari bisa punya sebagian hari selesai dan sebagian belum.
- Saat user simpan ulang itinerary yang sudah punya `itineraryId`, itu adalah **update in-place**, bukan create baru.

→ Butuh: CRUD itinerary, endpoint tandai satu hari sebagai selesai (bukan seluruh itinerary).

### `MyReviewsService`
Ulasan yang ditulis user: `destinationId`, `rating`, `text`, `photos`, `likes`, dll.
→ Butuh: endpoint create review, get review milik user (untuk "Ulasan Saya" di profil), like/unlike.

### `NotificationSettingsService`
Preferensi notifikasi: `crowdAlerts`, `recommendationAlerts`, `itineraryReminders`, `promoAlerts` (semua boolean).
→ Butuh: endpoint get/update preferensi notifikasi user, kemungkinan terhubung ke sistem push notification (FCM).

### `LanguageService`
Preferensi bahasa (`id`/`en`). Catatan: seluruh teks aplikasi saat ini **hardcoded Bahasa Indonesia** — memilih English baru menyimpan preferensi, belum benar-benar menerjemahkan UI. Prioritas rendah untuk backend.

### `destinations_data.dart`
Saat ini katalog destinasi (nama, lokasi, kategori, rating, deskripsi, gambar) masih berupa data statis yang di-hardcode di file Dart, direferensikan lewat `id`.
→ Ini kandidat utama untuk jadi endpoint `GET /destinations` dan `GET /destinations/{id}` — kode di frontend sudah sengaja ditulis mengambil data lewat `id` (bukan `name`) supaya polanya sudah mirip cara manggil REST API.

## 6. Fitur yang Belum Terhubung Sama Sekali

- **Autentikasi**: `login_screen.dart` & `register_screen.dart` murni UI, belum ada pemanggilan API auth.
- **Prediksi kepadatan**: `crowd_prediction_screen.dart` — perlu dikonfirmasi ke tim: apakah datanya dari model/algoritma backend, atau data statis/mock sementara.
- **Itinerary berbasis AI**: `ai_itinerary_screen.dart` — perlu dikonfirmasi: AI generation-nya akan dipanggil dari backend (disarankan, supaya API key model AI tidak terekspos di aplikasi mobile) atau ada rencana lain.

## 7. Hal yang Perlu Dikonfirmasi ke Tim Backend

- [ ] Format autentikasi yang dipakai (JWT? Session? Firebase Auth?)
- [ ] Apakah upload foto (profil & review) langsung ke backend, atau ke object storage terpisah (S3/GCS/dsb) dengan backend hanya simpan URL-nya
- [ ] Skema endpoint destinasi — apakah kategori, rating, dan review agregat dihitung di backend atau tetap sebagian statis
- [ ] Mekanisme AI itinerary generation — model apa yang dipakai dan siapa yang akan memanggilnya (backend disarankan, bukan langsung dari app)
- [ ] Sistem push notification yang akan dipakai (FCM paling umum untuk Flutter)

## 8. Catatan Konfigurasi (Belum untuk Produksi)

- `applicationId` Android masih `com.example.smarttrip` (default template, belum diganti ke ID final).
- Build release Android masih pakai **debug signing config** (`signingConfig = signingConfigs.getByName("debug")`) — wajib diganti sebelum rilis produksi.

## 9. Cara Menjalankan Project (untuk referensi)

```bash
flutter pub get
flutter run
```

Tidak ada file `.env` atau kredensial khusus yang dibutuhkan saat ini karena belum ada integrasi API eksternal.