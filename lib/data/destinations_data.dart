import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

// ================================================================
// DESTINATIONS DATA
// ================================================================
//
// Sumber data destinasi bersama, dipakai oleh DestinationSelectionScreen
// (pilih manual) dan AIItineraryScreen (rekomendasi AI) supaya keduanya
// selalu mengacu ke daftar destinasi yang sama persis.
//
// CATATAN MIGRASI: SavedDestinationsService, LoveButton, CategoryBadge,
// dan MyReviewsService yang dulu nempel di file ini sudah dipindah ke
// services/saved_destinations_service.dart, widgets/love_button.dart,
// widgets/category_badge.dart, dan services/my_reviews_service.dart.
// File ini sekarang murni data + helper terkait data saja.
//
// ================================================================
//
// CATATAN 'latitude' & 'longitude':
// Nilainya perkiraan/dummy (diambil dari lokasi umum tempat tersebut
// di Lampung), BUKAN hasil geocoding presisi -- tujuannya supaya
// peta rute di ItineraryDetailScreen (dan layar lain yang butuh
// koordinat) selalu punya titik untuk ditampilkan walau belum
// tersambung ke backend/geocoding asli. Tinggal timpa nilainya kalau
// nanti sudah ada koordinat pasti.
//
// Yang WAJIB dijaga: titiknya harus tetap jatuh di area kabupaten/
// kota yang sesuai dengan field 'location' di bawah (mis. destinasi
// dengan 'location': 'Pesawaran' harus punya lat/lng di wilayah
// Kabupaten Pesawaran), supaya peta rute tidak menampilkan titik yang
// nyasar ke kabupaten/kota lain. Kalau nambah destinasi baru, cek
// dulu bounding box kabupaten/kota-nya di kLampungRegencyBounds
// (lihat bagian "LAMPUNG REGENCY BOUNDS" di bawah, dekat
// destinationMatchesCity) supaya koordinat dummy yang dipasang tetap
// masuk akal.
//
// ================================================================

const List<Map<String, String>> kDestinationsData = [
  // ==============================================================
  // KULINER
  // ==============================================================

  {
    'id': 'resto_2',
    'latitude': '-5.3971',
    'longitude': '105.2668',
    'name': 'Resto 2',
    'location': 'Lampung',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '120 review',
    'image': 'assets/images/resto2.jpg',
    'description':
        'Tempat kuliner yang menyediakan berbagai pilihan makanan dan minuman untuk dinikmati bersama keluarga maupun teman.',
  },

  {
    'id': 'resto_1',
    'latitude': '-5.395',
    'longitude': '105.263',
    'name': 'Resto 1',
    'location': 'Lampung',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '150 review',
    'image': 'assets/images/resto1.jpg',
    'description':
        'Salah satu pilihan tempat kuliner di Lampung dengan berbagai menu makanan yang cocok untuk wisatawan.',
  },

  {
    'id': 'cafe_2',
    'latitude': '-5.392',
    'longitude': '105.26',
    'name': 'Cafe 2',
    'location': 'Lampung',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '180 review',
    'image': 'assets/images/cafe2.jpg',
    'description':
        'Cafe dengan suasana nyaman yang cocok untuk bersantai dan menikmati berbagai pilihan makanan dan minuman.',
  },

  {
    'id': 'cafe_1',
    'latitude': '-5.39',
    'longitude': '105.258',
    'name': 'Cafe 1',
    'location': 'Lampung',
    'category': 'Kuliner',
    'rating': '4.4',
    'reviews': '95 review',
    'image': 'assets/images/cafe1.jpg',
    'description':
        'Tempat bersantai dengan pilihan makanan dan minuman yang dapat menjadi salah satu tujuan wisata kuliner.',
  },

  {
    'id': 'mie_khodon',
    'latitude': '-5.42',
    'longitude': '105.25',
    'name': 'Mie Khodon',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '410 review',
    'image': 'assets/images/mie_khodon.jpg',
    'description':
        'Kedai mie legendaris yang sudah berjualan sejak tahun 1960-an, terkenal dengan cita rasa khas dan pelanggan yang rela mengantre.',
  },

  {
    'id': 'seruit_khas_lampung',
    'latitude': '-5.415',
    'longitude': '105.255',
    'name': 'Seruit Khas Lampung',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '260 review',
    'image': 'assets/images/seruit_khas_lampung.jpg',
    'description':
        'Rumah makan yang menyajikan seruit, hidangan khas Lampung berupa ikan bakar dengan sambal terasi, tempoyak, dan lalapan.',
  },

  {
    'id': 'pindang_sehat_gunung_sugih',
    'latitude': '-4.953',
    'longitude': '105.217',
    'name': 'Pindang Sehat Gunung Sugih',
    'location': 'Lampung Tengah',
    'category': 'Kuliner',
    'rating': '4.4',
    'reviews': '140 review',
    'image': 'assets/images/pindang_sehat_gunung_sugih.jpg',
    'description':
        'Rumah makan khas Lampung Tengah yang menyajikan pindang ikan segar dengan kuah asam pedas yang menyegarkan.',
  },

  {
    'id': 'kedai_kopi_robusta_lampung',
    'latitude': '-5.38',
    'longitude': '105.27',
    'name': 'Kedai Kopi Robusta Lampung',
    'location': 'Lampung',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '300 review',
    'image': 'assets/images/kedai_kopi_robusta_lampung.jpg',
    'description':
        'Kedai kopi yang menyajikan kopi robusta khas Lampung, salah satu daerah penghasil kopi robusta terbesar di Indonesia.',
  },

  // ==============================================================
  // ALAM
  // ==============================================================

  {
    'id': 'air_terjun_curup',
    'latitude': '-4.7',
    'longitude': '105.2',
    'name': 'Air Terjun Curup',
    'location': 'Lampung Tengah',
    'category': 'Alam',
    'rating': '4.6',
    'reviews': '150 review',
    'image': 'assets/images/air_terjun.jpg',
    'description':
        'Air Terjun Curup merupakan destinasi wisata alam dengan suasana sejuk, pemandangan hijau, dan aliran air yang menyegarkan, cocok untuk bersantai bersama keluarga maupun teman.',
  },

  {
    'id': 'danau_ranau',
    'latitude': '-4.8794',
    'longitude': '103.9313',
    'name': 'Danau Ranau',
    'location': 'Lampung Barat',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '320 review',
    'image': 'assets/images/danau_ranau.jpg',
    'description':
        'Danau Ranau merupakan destinasi wisata alam dengan panorama danau dan pegunungan yang indah.',
  },

  {
    'id': 'pantai_gigi_hiu',
    'latitude': '-5.6667',
    'longitude': '104.5333',
    'name': 'Pantai Gigi Hiu',
    'location': 'Tanggamus',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '280 review',
    'image': 'assets/images/pantai_gigi_hiu.jpg',
    'description':
        'Pantai dengan formasi batu karang unik yang menjadi salah satu daya tarik wisata alam di Lampung.',
  },

  {
    'id': 'pantai_klara',
    'latitude': '-5.5667',
    'longitude': '105.1667',
    'name': 'Pantai Klara',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '230 review',
    'image': 'assets/images/pantai_klara.jpg',
    'description':
        'Pantai dengan suasana tropis dan pemandangan laut yang cocok untuk menikmati waktu bersama keluarga dan teman.',
  },

  {
    'id': 'pantai_mutun',
    'latitude': '-5.5347',
    'longitude': '105.2181',
    'name': 'Pantai Mutun',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '250 review',
    'image': 'assets/images/pantai_mutun.jpg',
    'description':
        'Pantai populer di Lampung dengan pasir pantai dan pemandangan laut yang menjadi pilihan wisatawan.',
  },

  {
    'id': 'pantai_sari_ringgung',
    'latitude': '-5.53',
    'longitude': '105.19',
    'name': 'Pantai Sari Ringgung',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '260 review',
    'image': 'assets/images/pantai_sari_ringgung.jpg',
    'description':
        'Destinasi wisata pantai dengan panorama laut dan berbagai aktivitas wisata yang dapat dinikmati pengunjung.',
  },

  {
    'id': 'pulau_pahawang',
    'latitude': '-5.6167',
    'longitude': '105.1667',
    'name': 'Pulau Pahawang',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '350 review',
    'image': 'assets/images/pulau_pahawang.jpg',
    'description':
        'Pulau wisata dengan panorama laut yang indah dan dikenal sebagai salah satu destinasi wisata bahari Lampung.',
  },

  {
    'id': 'pulau_wayang',
    'latitude': '-5.63',
    'longitude': '105.15',
    'name': 'Pulau Wayang',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '290 review',
    'image': 'assets/images/pulau_wayang.jpg', 
    'description':
        'Destinasi wisata bahari dengan panorama pulau dan laut yang menawarkan pengalaman menikmati keindahan alam.',
  },

  {
    'id': 'teluk_kiluan',
    'latitude': '-5.7333',
    'longitude': '105.05',
    'name': 'Teluk Kiluan',
    'location': 'Tanggamus',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '400 review',
    'image': 'assets/images/teluk_kiluan.jpg',
    'description':
        'Teluk yang terkenal dengan atraksi lumba-lumba hidung botol liar yang dapat disaksikan langsung dari perahu nelayan pada pagi hari.',
  },

  {
    'id': 'taman_nasional_way_kambas',
    'latitude': '-4.9333',
    'longitude': '105.7833',
    'name': 'Taman Nasional Way Kambas',
    'location': 'Lampung Timur',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '310 review',
    'image': 'assets/images/way_kambas.jpg',
    'description':
        'Salah satu taman nasional tertua di Indonesia yang menjadi pusat konservasi gajah, tempat pengunjung dapat mengamati gajah liar dan mengikuti tur konservasi.',
  },

  {
    'id': 'air_terjun_way_lalaan',
    'latitude': '-5.4667',
    'longitude': '104.6167',
    'name': 'Air Terjun Way Lalaan',
    'location': 'Tanggamus',
    'category': 'Alam',
    'rating': '4.5',
    'reviews': '180 review',
    'image': 'assets/images/way_lalaan.jpg',
    'description':
        'Air terjun bertingkat dua yang mudah diakses di dekat Kota Agung, dengan suasana sejuk dan pemandangan yang asri.',
  },

  {
    'id': 'danau_suoh',
    'latitude': '-5.1667',
    'longitude': '104.2167',
    'name': 'Danau Suoh',
    'location': 'Lampung Barat',
    'category': 'Alam',
    'rating': '4.6',
    'reviews': '150 review',
    'image': 'assets/images/danau_suoh.jpg',
    'description':
        'Kawasan tiga danau dengan warna air berbeda, dilengkapi sumber air panas alami dan aktivitas geotermal yang khas.',
  },

  {
    'id': 'pulau_tegal_mas',
    'latitude': '-5.6',
    'longitude': '105.1833',
    'name': 'Pulau Tegal Mas',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '220 review',
    'image': 'assets/images/pulau_tegal_mas.jpg',
    'description':
        'Pulau dengan resort terapung yang kerap disebut "Maldives-nya Lampung", cocok untuk snorkeling dan diving.',
  },

  {
    'id': 'pantai_tanjung_setia',
    'latitude': '-5.3333',
    'longitude': '103.9167',
    'name': 'Pantai Tanjung Setia',
    'location': 'Lampung Barat',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '190 review',
    'image': 'assets/images/pantai_tanjung_setia.jpg',
    'description':
        'Pantai dengan ombak tinggi yang populer untuk berselancar, dilengkapi pasir putih dan pemandangan matahari terbenam.',
  },

  {
    'id': 'air_terjun_curug_tujuh',
    'latitude': '-5.4833',
    'longitude': '105.1',
    'name': 'Air Terjun Curug Tujuh',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.6',
    'reviews': '160 review',
    'image': 'assets/images/curug_tujuh.jpg',
    'description':
        'Air terjun tujuh tingkat dengan ketinggian mencapai 75 meter, masih asri dan cocok untuk trekking ringan.',
  },

  {
    'id': 'teluk_hantu',
    'latitude': '-5.6',
    'longitude': '105.2',
    'name': 'Teluk Hantu',
    'location': 'Lampung',
    'category': 'Alam',
    'rating': '4.5',
    'reviews': '130 review',
    'image': 'assets/images/teluk_hantu.jpg',
    'description':
        'Destinasi pesisir dengan air laut jernih, deretan bebatuan eksotis, dan suasana tenang yang cocok untuk relaksasi.',
  },

  {
    'id': 'anak_krakatau',
    'latitude': '-6.1022',
    'longitude': '105.4231',
    'name': 'Anak Krakatau',
    'location': 'Lampung Selatan',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '270 review',
    'image': 'assets/images/anak_krakatau.jpg',
    'description':
        'Gunung berapi legendaris di Selat Sunda yang dapat diakses via Dermaga Canti, Kalianda, menawarkan panorama spektakuler dan trekking ringan.',
  },

  {
    'id': 'pantai_kyokko',
    'latitude': '-5.75',
    'longitude': '105.5667',
    'name': 'Pantai Kyokko',
    'location': 'Lampung Selatan',
    'category': 'Alam',
    'rating': '4.6',
    'reviews': '210 review',
    'image': 'assets/images/pantai_kyokko.jpg',
    'description':
        'Pantai dengan air laut biru jernih dan pasir putih bersih yang sedang naik daun di kalangan wisatawan.',
  },

  // ==============================================================
  // BUDAYA
  // ==============================================================

  {
    'id': 'museum_lampung',
    'latitude': '-5.3891',
    'longitude': '105.2416',
    'name': 'Museum Lampung',
    'location': 'Bandar Lampung',
    'category': 'Budaya',
    'rating': '4.5',
    'reviews': '180 review',
    'image': 'assets/images/museum_lampung.jpg',
    'description':
        'Museum yang menjadi salah satu tempat untuk mengenal sejarah, budaya, dan berbagai peninggalan masyarakat Lampung.',
  },

  {
    'id': 'siger',
    'latitude': '-5.8722',
    'longitude': '105.7561',
    'name': 'Siger',
    'location': 'Lampung',
    'category': 'Budaya',
    'rating': '4.6',
    'reviews': '200 review',
    'image': 'assets/images/siger.png',
    'description':
        'Siger merupakan salah satu simbol budaya Lampung yang memiliki nilai penting dalam identitas dan tradisi masyarakat Lampung.',
  },

  {
    'id': 'danau_tirta_gangga',
    'latitude': '-4.97',
    'longitude': '105.27',
    'name': 'Danau Tirta Gangga',
    'location': 'Lampung Tengah',
    'category': 'Budaya',
    'rating': '4.5',
    'reviews': '170 review',
    'image': 'assets/images/danau_tirta_gangga.jpg',
    'description':
        'Danau yang juga menjadi tempat wisata religi, dengan sebuah pura yang tampak berdiri di atas air, dipengaruhi tradisi masyarakat Hindu setempat.',
  },

  // ==============================================================
  // BUATAN
  // ==============================================================

  {
    'id': 'puncak_mas',
    'latitude': '-5.36',
    'longitude': '105.25',
    'name': 'Puncak Mas',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.6',
    'reviews': '210 review',
    'image': 'assets/images/puncak_mas.jpg',
    'description':
        'Destinasi wisata buatan dengan pemandangan Kota Bandar Lampung yang cocok untuk menikmati suasana dan berfoto.',
  },

  {
    'id': 'lembah_hijau',
    'latitude': '-5.3833',
    'longitude': '105.2167',
    'name': 'Lembah Hijau',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.5',
    'reviews': '380 review',
    'image': 'assets/images/lembah_hijau.jpg',
    'description':
        'Taman rekreasi outdoor dengan water park, kebun binatang mini, dan wahana permainan yang cocok untuk liburan keluarga.',
  },

  {
    'id': 'trans_studio_mini_lampung',
    'latitude': '-5.3971',
    'longitude': '105.2668',
    'name': 'Trans Studio Mini Lampung',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.4',
    'reviews': '240 review',
    'image': 'assets/images/trans_studio_mini_lampung.jpg',
    'description':
        'Taman hiburan indoor dengan berbagai wahana permainan yang cocok untuk dikunjungi bersama keluarga dan anak-anak.',
  },

  {
    'id': 'navara_city_park',
    'latitude': '-5.37',
    'longitude': '105.26',
    'name': 'Navara City Park',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.5',
    'reviews': '160 review',
    'image': 'assets/images/navara_city_park.jpg',
    'description':
        'Kawasan rekreasi terpadu terbaru di Bandar Lampung dengan area bermain, ruang rekreasi keluarga, dan area kuliner modern.',
  },

  {
    'id': 'bukit_sakura_kemiling',
    'latitude': '-5.39',
    'longitude': '105.2',
    'name': 'Bukit Sakura Kemiling',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.4',
    'reviews': '190 review',
    'image': 'assets/images/bukit_sakura_kemiling.jpg',
    'description':
        'Taman bunga dengan konsep ala Jepang yang menjadi spot foto populer, berjarak sekitar 20-30 menit dari pusat kota.',
  },
];

// ================================================================
// GALERI FOTO TAMBAHAN PER DESTINASI (OPSIONAL)
// ================================================================
//
// Sebagian besar destinasi baru punya 1 foto (field 'image' di atas),
// jadi galeri di halaman detail cukup pakai foto utama itu saja.
//
// Untuk destinasi yang KEBETULAN sudah punya beberapa foto sudut
// berbeda, daftarkan di sini (dikunci pakai 'id', bukan 'name', biar
// tetap valid walau nama destinasinya di-rename nanti). Dipisah dari
// kDestinationsData supaya tidak perlu ubah struktur Map<String,String>
// di atas hanya untuk sebagian kecil kasus yang punya banyak foto.
//
// DetailDestinationScreen sudah otomatis fallback ke foto utama kalau
// suatu id tidak ada di map ini -- jadi aman ditambah kapan saja tanpa
// mempengaruhi destinasi lain.
// ================================================================

const Map<String, List<String>> kDestinationGalleryImages = {
  'pulau_wayang': [
    'assets/images/pulau_wayang.jpg',
    'assets/images/pulau_wayang2.jpg',
    'assets/images/pulau_wayang3.jpg',
    'assets/images/pulau_wayang4.jpg',
  ],
};

// ================================================================
// CARI SATU DESTINASI BERDASARKAN ID
// ================================================================
//
// Ini lookup utama yang dipakai layar-layar yang perlu menampilkan
// destinasi tertentu (recommendation, home, crowd prediction).
//
// Sengaja pakai 'id' (bukan 'name') sebagai kunci karena itu yang akan
// dipakai backend sungguhan nanti (mis. GET /destinations/{id}) — nama
// destinasi bisa berubah (typo, rename, terjemahan), id tidak. Waktu
// backend-nya sudah ada, fungsi ini tinggal diganti isinya jadi
// pemanggilan API; pemanggilnya di layar-layar lain tidak perlu ubah
// apa pun karena tanda tangan fungsinya tetap sama.
//
// ================================================================

Map<String, String>? findDestinationById(String id) {
  for (final destination in kDestinationsData) {
    if (destination['id'] == id) {
      return destination;
    }
  }

  return null;
}

// ================================================================
// [DUMMY] JAM OPERASIONAL PER DESTINASI
// ================================================================
//
// TODO(backend): ganti dengan field 'openHour'/'closeHour' asli per
// destinasi (dari database), lalu baca langsung dari
// destination['openHour'] dkk di pemanggilnya. Untuk sekarang (dummy
// front-end), jam operasional diperkirakan berdasarkan KATEGORI saja,
// supaya AI tetap bisa menghitung jam berangkat & jadwal kunjungan
// yang masuk akal tanpa perlu mengisi jam buka satu-satu untuk
// puluhan destinasi.
//
// Dikembalikan sebagai jam dalam format 24 jam (0-23). closeHour
// dianggap masih di hari yang sama (tidak ada destinasi yang buka
// lewat tengah malam di data dummy ini).
//
// ================================================================

class OperatingHours {
  final int openHour;
  final int closeHour;

  const OperatingHours({required this.openHour, required this.closeHour});
}

OperatingHours operatingHoursFor(Map<String, dynamic> destination) {
  final String category = (destination['category'] as String?) ?? 'Alam';

  switch (category) {
    case 'Kuliner':
      // Resto/kafe: buka agak siang, tutup malam.
      return const OperatingHours(openHour: 8, closeHour: 22);

    case 'Budaya':
      // Museum/situs budaya: jam kantor.
      return const OperatingHours(openHour: 8, closeHour: 16);

    case 'Buatan':
      // Taman rekreasi/wahana buatan.
      return const OperatingHours(openHour: 9, closeHour: 21);

    case 'Alam':
    default:
      // Pantai/air terjun/danau: buka pagi, tutup sore (mengikuti
      // cahaya matahari).
      return const OperatingHours(openHour: 6, closeHour: 18);
  }
}

// ================================================================
// [DUMMY] ESTIMASI DURASI KUNJUNGAN PER KATEGORI (NUMERIK)
// ================================================================
//
// Versi numerik (dalam jam, boleh pecahan) dari estimasi durasi
// kunjungan, dipakai untuk perhitungan jadwal (jam mulai/selesai).
// Nilainya sengaja disamakan dengan label yang ditampilkan di UI
// (lihat _estimateDuration di ai_itinerary_screen.dart) supaya jam
// yang dihitung dan teks durasi yang ditampilkan tidak pernah beda.
//
// ================================================================

double visitDurationHoursFor(String category) {
  switch (category) {
    case 'Kuliner':
      return 1.0;
    case 'Budaya':
      return 1.5;
    case 'Buatan':
      return 2.0;
    case 'Alam':
    default:
      return 2.5;
  }
}

// ================================================================
// [DUMMY] ESTIMASI WAKTU TEMPUH ANTAR TITIK
// ================================================================
//
// TODO(backend): ganti dengan hasil dari routing API sungguhan
// (mis. OSRM/Google Directions) yang memperhitungkan kondisi jalan
// asli, bukan garis lurus. Untuk sekarang (dummy front-end), waktu
// tempuh dihitung dari jarak garis lurus (haversine) antara dua
// koordinat, dibagi kecepatan rata-rata sesuai kendaraan, lalu
// ditambah faktor kelokan jalan (+30%) supaya tidak terlalu optimis
// dibanding rute jalan sungguhan.
//
// ================================================================

double _averageSpeedKmhFor(String? vehicle) {
  switch (vehicle) {
    case 'Motor':
      return 45;
    case 'Bus':
      return 35;
    case 'Mobil':
    default:
      return 50;
  }
}

double haversineDistanceKm(LatLng a, LatLng b) {
  const double earthRadiusKm = 6371;

  double toRad(double degree) => degree * (math.pi / 180);

  final double dLat = toRad(b.latitude - a.latitude);
  final double dLon = toRad(b.longitude - a.longitude);

  final double lat1 = toRad(a.latitude);
  final double lat2 = toRad(b.latitude);

  final double h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));

  return earthRadiusKm * c;
}

Duration estimateTravelTime(LatLng from, LatLng to, {String? vehicle}) {
  final double distanceKm = haversineDistanceKm(from, to);

  const double roadWindingFactor = 1.3;

  final double speedKmh = _averageSpeedKmhFor(vehicle);

  final double hours = (distanceKm * roadWindingFactor) / speedKmh;

  final int minutes = (hours * 60).round().clamp(5, 24 * 60);

  return Duration(minutes: minutes);
}

// ================================================================
// AMBIL KOORDINAT (LatLng) DARI SATU ENTRI DESTINASI
// ================================================================

LatLng? coordinateOfDestination(Map<String, dynamic> destination) {
  final double? lat =
      double.tryParse(destination['latitude']?.toString() ?? '');
  final double? lon =
      double.tryParse(destination['longitude']?.toString() ?? '');

  if (lat == null || lon == null) return null;

  return LatLng(lat, lon);
}

// ================================================================
// CARI SATU DESTINASI BERDASARKAN NAMA (LEGACY)
// ================================================================
//
// Dipertahankan untuk kompatibilitas tampilan/pencarian teks bebas
// (mis. search bar). Untuk referensi ke destinasi tertentu di dalam
// kode (bukan hasil ketikan user), pakai findDestinationById di atas,
// bukan ini — supaya tidak rapuh kalau nama berubah.
//
// ================================================================

Map<String, String>? findDestinationByName(String name) {
  final String normalizedName = name.trim().toLowerCase();

  for (final destination in kDestinationsData) {
    if (destination['name']!.toLowerCase() == normalizedName) {
      return destination;
    }
  }

  return null;
}

// ================================================================
// COCOKKAN LOKASI DESTINASI DENGAN KOTA/KABUPATEN TUJUAN
// ================================================================
//
// `travelCity` berasal dari daftar kota/kabupaten di
// TravelInformationScreen, contoh: "Kabupaten Pesawaran",
// "Kota Bandar Lampung". `location` berasal dari field 'location'
// pada kDestinationsData, contoh: "Pesawaran", "Bandar Lampung".
//
// Destinasi dengan location generik "Lampung" (tidak terikat
// kabupaten/kota tertentu) dianggap selalu cocok, supaya kota-kota
// yang belum punya destinasi spesifik tetap menampilkan sesuatu.
//
// ================================================================

bool destinationMatchesCity(String location, String? travelCity) {
  if (travelCity == null || travelCity.trim().isEmpty) return true;

  final String normalizedCity = travelCity
      .replaceFirst(RegExp(r'^Kabupaten\s+', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^Kota\s+', caseSensitive: false), '')
      .trim()
      .toLowerCase();

  final String normalizedLocation = location.trim().toLowerCase();

  if (normalizedLocation == 'lampung') return true;

  return normalizedLocation.contains(normalizedCity) ||
      normalizedCity.contains(normalizedLocation);
}

// ================================================================
// LAMPUNG REGENCY BOUNDS
// ================================================================
//
// Bounding box PERKIRAAN (bukan batas administratif presisi) untuk
// tiap kabupaten/kota di Provinsi Lampung. Dipakai untuk menghasilkan
// titik koordinat dummy/fallback yang setidaknya jatuh di wilayah
// kabupaten/kota yang benar -- BUKAN untuk keperluan lain yang butuh
// akurasi geografis (mis. geocoding sungguhan, hitung jarak presisi).
//
// Dipakai oleh:
// - Bagian di atas (kDestinationsData), sebagai acuan waktu
//   menentukan/mengoreksi 'latitude'/'longitude' dummy tiap destinasi
//   supaya konsisten dengan field 'location'-nya.
// - ManualScheduleScreen, untuk membuat titik keberangkatan dummy
//   (startLatitude/startLongitude) kalau user tidak sempat memilih
//   lokasi awal lewat peta/GPS -- titik dummy ini dibuat jatuh di
//   wilayah kabupaten/kota TUJUAN (destinationCity) yang sudah
//   dipilih user, bukan titik tetap di satu tempat saja.
// - ItineraryDetailScreen, sebagai fallback terakhir kalau data
//   jadwal lama/tidak lengkap tidak punya startLatitude/
//   startLongitude sama sekali.
//
// ================================================================

class RegencyBounds {
  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;

  const RegencyBounds({
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
  });

  LatLng get center =>
      LatLng((latMin + latMax) / 2, (lonMin + lonMax) / 2);
}

// Key dinormalisasi: huruf kecil, tanpa prefix "Kabupaten "/"Kota ".
const Map<String, RegencyBounds> kLampungRegencyBounds = {
  'bandar lampung': RegencyBounds(
    latMin: -5.45,
    latMax: -5.33,
    lonMin: 105.18,
    lonMax: 105.32,
  ),
  'metro': RegencyBounds(
    latMin: -5.15,
    latMax: -5.08,
    lonMin: 105.28,
    lonMax: 105.34,
  ),
  'lampung selatan': RegencyBounds(
    latMin: -6.20,
    latMax: -5.35,
    lonMin: 105.15,
    lonMax: 105.80,
  ),
  'lampung tengah': RegencyBounds(
    latMin: -5.05,
    latMax: -4.60,
    lonMin: 104.85,
    lonMax: 105.55,
  ),
  'lampung timur': RegencyBounds(
    latMin: -5.30,
    latMax: -4.55,
    lonMin: 105.35,
    lonMax: 105.95,
  ),
  'lampung utara': RegencyBounds(
    latMin: -5.05,
    latMax: -4.55,
    lonMin: 104.55,
    lonMax: 105.05,
  ),
  'lampung barat': RegencyBounds(
    latMin: -5.35,
    latMax: -4.75,
    lonMin: 103.90,
    lonMax: 104.55,
  ),
  'pesawaran': RegencyBounds(
    latMin: -5.70,
    latMax: -5.35,
    lonMin: 104.95,
    lonMax: 105.30,
  ),
  'pringsewu': RegencyBounds(
    latMin: -5.45,
    latMax: -5.30,
    lonMin: 104.85,
    lonMax: 105.10,
  ),
  'tanggamus': RegencyBounds(
    latMin: -5.85,
    latMax: -5.25,
    lonMin: 104.30,
    lonMax: 105.15,
  ),
  'tulang bawang': RegencyBounds(
    latMin: -4.60,
    latMax: -4.10,
    lonMin: 105.30,
    lonMax: 105.85,
  ),
  'tulang bawang barat': RegencyBounds(
    latMin: -4.65,
    latMax: -4.30,
    lonMin: 104.85,
    lonMax: 105.30,
  ),
  'way kanan': RegencyBounds(
    latMin: -4.75,
    latMax: -4.20,
    lonMin: 104.30,
    lonMax: 104.95,
  ),
  'mesuji': RegencyBounds(
    latMin: -4.15,
    latMax: -3.60,
    lonMin: 105.15,
    lonMax: 105.75,
  ),
  'pesisir barat': RegencyBounds(
    latMin: -5.75,
    latMax: -4.95,
    lonMin: 103.80,
    lonMax: 104.35,
  ),
};

// Normalisasi nama kabupaten/kota dipisah jadi fungsi sendiri (bukan
// cuma inline di destinationMatchesCity di atas) supaya bisa dipakai
// ulang oleh findRegencyBounds/coordinateForRegency di bawah, tanpa
// duplikasi pola RegExp-nya.
String normalizeRegencyName(String name) {
  return name
      .replaceFirst(RegExp(r'^Kabupaten\s+', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^Kota\s+', caseSensitive: false), '')
      .trim()
      .toLowerCase();
}

RegencyBounds? findRegencyBounds(String? regencyName) {
  if (regencyName == null || regencyName.trim().isEmpty) return null;

  return kLampungRegencyBounds[normalizeRegencyName(regencyName)];
}

// ================================================================
// TITIK DUMMY DI DALAM WILAYAH KABUPATEN/KOTA
// ================================================================
//
// Menghasilkan LatLng acak (tidak presisi, sengaja) tapi tetap jatuh
// di dalam bounding box kabupaten/kota yang diminta. Kalau nama
// kabupaten/kota tidak dikenali/kosong, fallback ke wilayah Bandar
// Lampung (ibu kota provinsi) supaya tetap ada titik yang masuk akal
// untuk ditampilkan, bukan sekadar 0,0.
//
// `seed` opsional dipakai supaya hasilnya stabil/tidak berubah-ubah
// untuk input yang sama (mis. dipanggil ulang tanpa acak baru tiap
// rebuild) -- kalau tidak diisi, titik dibuat betul-betul acak
// setiap kali dipanggil.
//
// ================================================================

LatLng coordinateForRegency(String? regencyName, {Object? seed}) {
  final RegencyBounds bounds =
      findRegencyBounds(regencyName) ??
      kLampungRegencyBounds['bandar lampung']!;

  final math.Random random =
      seed != null ? math.Random(seed.hashCode) : math.Random();

  final double lat =
      bounds.latMin + random.nextDouble() * (bounds.latMax - bounds.latMin);

  final double lon =
      bounds.lonMin + random.nextDouble() * (bounds.lonMax - bounds.lonMin);

  return LatLng(lat, lon);
}

// ================================================================
// SAVED DESTINATIONS SERVICE
// ================================================================
//
// Sumber kebenaran tunggal (single source of truth) untuk destinasi
// mana saja yang sudah di-"love"/disimpan user. Dipakai bareng oleh
// semua kartu destinasi (home, rekomendasi, pencarian, prediksi
// kepadatan) supaya statusnya selalu sinkron di semua layar, dan oleh
// ProfileScreen untuk menampilkan daftar "Destinasi Tersimpan".
//
// Disimpan di memori (in-memory) selama aplikasi berjalan lewat
// ValueNotifier bawaan Flutter, jadi tidak perlu package state
// management tambahan.
//
// ================================================================

