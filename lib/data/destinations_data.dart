import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

// Data destinasi bersama, dipakai oleh DestinationSelectionScreen dan
// AIItineraryScreen supaya keduanya mengacu ke daftar yang sama.
//
// 'latitude'/'longitude' masih perkiraan (dummy), bukan hasil geocoding
// presisi -- tapi tetap dijaga jatuh di kabupaten/kota yang sesuai
// dengan 'location'. Cek kLampungRegencyBounds kalau nambah destinasi
// baru.

const List<Map<String, String>> kDestinationsData = [
  // ==============================================================
  // KULINER
  // ==============================================================

  {
    'id': 'resto_2',
    'latitude': '-5.3971',
    'longitude': '105.2668',
    'name': 'RM Pondok Rasa Kedaton',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '120 review',
    'image': 'assets/images/rm_pondok_rasa_kedaton.jpg',
    'description':
        'Tempat kuliner yang menyediakan berbagai pilihan makanan dan minuman untuk dinikmati bersama keluarga maupun teman.',
  },

  {
    'id': 'resto_1',
    'latitude': '-5.395',
    'longitude': '105.263',
    'name': 'RM Saung Kito Enggal',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '150 review',
    'image': 'assets/images/rm_saung_kito_enggal.jpg',
    'description':
        'Salah satu pilihan tempat kuliner di Lampung dengan berbagai menu makanan yang cocok untuk wisatawan.',
  },

  {
    'id': 'cafe_2',
    'latitude': '-5.392',
    'longitude': '105.26',
    'name': 'Cafe Rumah Kayu',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '180 review',
    'image': 'assets/images/cafe_rumah_kayu.jpg',
    'description':
        'Cafe dengan suasana nyaman yang cocok untuk bersantai dan menikmati berbagai pilihan makanan dan minuman.',
  },

  {
    'id': 'cafe_1',
    'latitude': '-5.39',
    'longitude': '105.258',
    'name': 'Kedai Senja Sultan Agung',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.4',
    'reviews': '95 review',
    'image': 'assets/images/kedai_senja_sultan_agung.jpg',
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
    'location': 'Bandar Lampung',
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
    'image': 'assets/images/air_terjun_curup.jpg',
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
    'location': 'Pesisir Barat',
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
    'location': 'Pesawaran',
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
    'location': 'Lampung Selatan',
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

  // ---------------- TAMBAHAN PER KABUPATEN/KOTA ----------------

  // BANDAR LAMPUNG

  {
    'id': 'pantai_puri_gading',
    'latitude': '-5.437',
    'longitude': '105.246',
    'name': 'Pantai Puri Gading',
    'location': 'Bandar Lampung',
    'category': 'Alam',
    'rating': '4.4',
    'reviews': '140 review',
    'image': 'assets/images/pantai_puri_gading.jpg',
    'description':
        'Pantai kota yang cukup mudah diakses dari pusat Bandar Lampung, cocok untuk menikmati sore hari sambil melihat aktivitas kapal di Teluk Lampung.',
  },

  {
    'id': 'taman_budaya_lampung',
    'latitude': '-5.397',
    'longitude': '105.267',
    'name': 'Taman Budaya Lampung',
    'location': 'Bandar Lampung',
    'category': 'Budaya',
    'rating': '4.3',
    'reviews': '90 review',
    'image': 'assets/images/taman_budaya_lampung.jpg',
    'description':
        'Pusat kesenian dan kebudayaan milik Pemerintah Provinsi Lampung, kerap dipakai untuk pertunjukan tari, teater, dan pameran seni tradisional.',
  },

  // LAMPUNG TENGAH

  {
    'id': 'angkringan_jemelik',
    'latitude': '-4.953',
    'longitude': '105.22',
    'name': 'Angkringan Jemelik',
    'location': 'Lampung Tengah',
    'category': 'Kuliner',
    'rating': '4.3',
    'reviews': '80 review',
    'image': 'assets/images/angkringan_jemelik.jpg',
    'description':
        'Angkringan dengan suasana santai khas Lampung Tengah, menyajikan aneka gorengan, sate, dan minuman hangat untuk nongkrong malam.',
  },

  {
    'id': 'islamic_center_lampung_tengah',
    'latitude': '-4.95',
    'longitude': '105.20',
    'name': 'Islamic Center Lampung Tengah',
    'location': 'Lampung Tengah',
    'category': 'Buatan',
    'rating': '4.2',
    'reviews': '65 review',
    'image': 'assets/images/islamic_center_lampung_tengah.jpg',
    'description':
        'Bangunan islamic center yang jadi salah satu landmark di Gunung Sugih, sering dipakai untuk kegiatan keagamaan dan acara kabupaten.',
  },

  // LAMPUNG BARAT

  {
    'id': 'kopi_liwa',
    'latitude': '-4.9667',
    'longitude': '104.0333',
    'name': 'Kopi Liwa',
    'location': 'Lampung Barat',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '110 review',
    'image': 'assets/images/kopi_liwa.jpg',
    'description':
        'Kedai kopi di Liwa yang menyajikan kopi robusta khas Lampung Barat, daerah pegunungan yang jadi salah satu sentra kopi robusta terbaik di Lampung.',
  },

  {
    'id': 'skala_brak_lamban_balak',
    'latitude': '-5.05',
    'longitude': '104.15',
    'name': 'Kompleks Adat Skala Brak',
    'location': 'Lampung Barat',
    'category': 'Budaya',
    'rating': '4.2',
    'reviews': '60 review',
    'image': 'assets/images/skala_brak_lamban_balak.jpg',
    'description':
        'Kawasan yang diyakini sebagai pusat kerajaan adat Skala Brak, cikal bakal masyarakat adat Lampung, dengan rumah adat dan tradisi yang masih dijaga masyarakat setempat.',
  },

  // TANGGAMUS

  {
    'id': 'waduk_batutegi',
    'latitude': '-5.283',
    'longitude': '104.75',
    'name': 'Waduk Batutegi',
    'location': 'Tanggamus',
    'category': 'Buatan',
    'rating': '4.5',
    'reviews': '170 review',
    'image': 'assets/images/waduk_batutegi.jpg',
    'description':
        'Bendungan besar yang jadi sumber irigasi dan air baku untuk Lampung, sekaligus menawarkan pemandangan danau buatan yang luas dikelilingi perbukitan.',
  },

  {
    'id': 'seafood_kota_agung',
    'latitude': '-5.483',
    'longitude': '104.617',
    'name': 'RM Seafood Teluk Semaka',
    'location': 'Tanggamus',
    'category': 'Kuliner',
    'rating': '4.3',
    'reviews': '70 review',
    'image': 'assets/images/seafood_kota_agung.jpg',
    'description':
        'Rumah makan seafood di tepi Teluk Semaka, Kota Agung, menyajikan hasil laut segar khas pesisir Tanggamus.',
  },

  // PESAWARAN

  {
    'id': 'seafood_pesawaran',
    'latitude': '-5.535',
    'longitude': '105.22',
    'name': 'RM Bahari Cempaka Mutun',
    'location': 'Pesawaran',
    'category': 'Kuliner',
    'rating': '4.3',
    'reviews': '90 review',
    'image': 'assets/images/seafood_pesawaran.jpg',
    'description':
        'Warung seafood di kawasan pesisir Pesawaran, dekat Pantai Mutun, menyajikan ikan dan hasil laut segar dengan pemandangan langsung ke arah pantai.',
  },

  // LAMPUNG TIMUR

  {
    'id': 'situs_purbakala_pugung_raharjo',
    'latitude': '-5.15',
    'longitude': '105.55',
    'name': 'Situs Purbakala Pugung Raharjo',
    'location': 'Lampung Timur',
    'category': 'Budaya',
    'rating': '4.4',
    'reviews': '95 review',
    'image': 'assets/images/situs_purbakala_pugung_raharjo.jpg',
    'description':
        'Kompleks situs arkeologi peninggalan masa megalitikum hingga klasik, berupa punden berundak, arca, dan benteng tanah kuno.',
  },

  {
    'id': 'rm_khas_sekampung',
    'latitude': '-5.10',
    'longitude': '105.50',
    'name': 'RM Pondok Sekampung Asri',
    'location': 'Lampung Timur',
    'category': 'Kuliner',
    'rating': '4.2',
    'reviews': '55 review',
    'image': 'assets/images/rm_khas_sekampung.jpg',
    'description':
        'Rumah makan yang menyajikan masakan khas Lampung untuk wisatawan yang mampir sebelum atau sesudah berkunjung ke Way Kambas.',
  },

  // LAMPUNG SELATAN

  {
    'id': 'seafood_kalianda',
    'latitude': '-5.75',
    'longitude': '105.57',
    'name': 'RM Seafood Dermaga Canti',
    'location': 'Lampung Selatan',
    'category': 'Kuliner',
    'rating': '4.2',
    'reviews': '75 review',
    'image': 'assets/images/seafood_kalianda.jpg',
    'description':
        'Rumah makan seafood dekat Dermaga Canti, Kalianda, titik transit populer wisatawan yang mau menyeberang ke Anak Krakatau atau Pantai Kyokko.',
  },

  // METRO

  {
    'id': 'taman_merdeka_metro',
    'latitude': '-5.114',
    'longitude': '105.3067',
    'name': 'Taman Merdeka Metro',
    'location': 'Metro',
    'category': 'Buatan',
    'rating': '4.4',
    'reviews': '130 review',
    'image': 'assets/images/taman_merdeka_metro.jpg',
    'description':
        'Taman kota utama di Metro yang jadi ruang publik favorit warga untuk olahraga, kuliner kaki lima, dan bersantai di sore hari.',
  },

  {
    'id': 'islamic_center_metro',
    'latitude': '-5.12',
    'longitude': '105.30',
    'name': 'Islamic Center Kota Metro',
    'location': 'Metro',
    'category': 'Budaya',
    'rating': '4.2',
    'reviews': '60 review',
    'image': 'assets/images/islamic_center_metro.jpg',
    'description':
        'Bangunan islamic center yang jadi landmark keagamaan sekaligus tempat kegiatan komunitas di Kota Metro.',
  },

  {
    'id': 'angkringan_metro',
    'latitude': '-5.11',
    'longitude': '105.31',
    'name': 'Angkringan Kamboja Metro',
    'location': 'Metro',
    'category': 'Kuliner',
    'rating': '4.3',
    'reviews': '70 review',
    'image': 'assets/images/angkringan_metro.jpg',
    'description':
        'Angkringan yang ramai jadi tempat nongkrong warga Metro, dikenal sebagai kota pendidikan dengan banyak pilihan tempat makan santai.',
  },

  // PRINGSEWU

  {
    'id': 'tugu_bambu_pringsewu',
    'latitude': '-5.359',
    'longitude': '104.973',
    'name': 'Tugu Bambu Pringsewu',
    'location': 'Pringsewu',
    'category': 'Buatan',
    'rating': '4.1',
    'reviews': '55 review',
    'image': 'assets/images/tugu_bambu_pringsewu.jpg',
    'description':
        'Tugu ikonik di pusat Kota Pringsewu yang jadi penanda dan spot foto favorit warga maupun pengunjung.',
  },

  {
    'id': 'pendopo_pringsewu',
    'latitude': '-5.358',
    'longitude': '104.974',
    'name': 'Pendopo Pringsewu',
    'location': 'Pringsewu',
    'category': 'Budaya',
    'rating': '4.0',
    'reviews': '40 review',
    'image': 'assets/images/pendopo_pringsewu.jpg',
    'description':
        'Bangunan pendopo kabupaten yang juga jadi tempat berbagai acara adat dan budaya di Pringsewu.',
  },

  {
    'id': 'rm_khas_pringsewu',
    'latitude': '-5.36',
    'longitude': '104.97',
    'name': 'RM Sinar Pringsewu',
    'location': 'Pringsewu',
    'category': 'Kuliner',
    'rating': '4.2',
    'reviews': '50 review',
    'image': 'assets/images/rm_khas_pringsewu.jpg',
    'description':
        'Rumah makan dengan menu khas Lampung yang jadi pilihan wisatawan yang transit di Pringsewu.',
  },

  // LAMPUNG UTARA

  {
    'id': 'tugu_macan_kotabumi',
    'latitude': '-4.8267',
    'longitude': '104.9033',
    'name': 'Tugu Macan Kotabumi',
    'location': 'Lampung Utara',
    'category': 'Buatan',
    'rating': '4.2',
    'reviews': '80 review',
    'image': 'assets/images/tugu_macan_kotabumi.jpg',
    'description':
        'Tugu patung macan yang jadi ikon dan penanda pusat Kota Kotabumi, ibu kota Kabupaten Lampung Utara.',
  },

  {
    'id': 'rm_khas_kotabumi',
    'latitude': '-4.83',
    'longitude': '104.90',
    'name': 'RM Durian Asli Kotabumi',
    'location': 'Lampung Utara',
    'category': 'Kuliner',
    'rating': '4.2',
    'reviews': '50 review',
    'image': 'assets/images/rm_khas_kotabumi.jpg',
    'description':
        'Rumah makan dengan sajian khas Lampung Utara, termasuk olahan durian yang jadi salah satu hasil bumi daerah ini.',
  },

  {
    'id': 'agrowisata_lampung_utara',
    'latitude': '-4.85',
    'longitude': '104.92',
    'name': 'Agrowisata Kebun Kopi Abung',
    'location': 'Lampung Utara',
    'category': 'Alam',
    'rating': '4.1',
    'reviews': '45 review',
    'image': 'assets/images/agrowisata_lampung_utara.jpg',
    'description':
        'Kebun agrowisata di kawasan Abung yang menawarkan suasana pedesaan dan perkebunan kopi khas Lampung Utara untuk wisata edukasi keluarga.',
  },

  // TULANG BAWANG

  {
    'id': 'wisata_alam_21',
    'latitude': '-4.35',
    'longitude': '105.55',
    'name': 'Wisata Alam 21',
    'location': 'Tulang Bawang',
    'category': 'Buatan',
    'rating': '4.0',
    'reviews': '45 review',
    'image': 'assets/images/wisata_alam_21.jpg',
    'description':
        'Kawasan wisata air dan area bermain keluarga di Gedung Aji, jadi pilihan rekreasi warga sekitar Tulang Bawang.',
  },

  {
    'id': 'rm_khas_menggala',
    'latitude': '-4.28',
    'longitude': '105.50',
    'name': 'RM Tepian Menggala',
    'location': 'Tulang Bawang',
    'category': 'Kuliner',
    'rating': '4.2',
    'reviews': '40 review',
    'image': 'assets/images/rm_khas_menggala.jpg',
    'description':
        'Rumah makan di Menggala, ibu kota Tulang Bawang, dengan menu khas masakan Lampung dan Sumatera.',
  },

  {
    'id': 'tepian_way_tulang_bawang',
    'latitude': '-4.30',
    'longitude': '105.45',
    'name': 'Dermaga Rakyat Tulang Bawang',
    'location': 'Tulang Bawang',
    'category': 'Alam',
    'rating': '4.0',
    'reviews': '35 review',
    'image': 'assets/images/tepian_way_tulang_bawang.jpg',
    'description':
        'Area di tepi Sungai Tulang Bawang yang jadi tempat bersantai warga sekitar sambil menikmati suasana sungai.',
  },

  // TULANG BAWANG BARAT

  {
    'id': 'masjid_agung_tubaba',
    'latitude': '-4.4398',
    'longitude': '105.0444',
    'name': 'Masjid Agung Tulang Bawang Barat',
    'location': 'Tulang Bawang Barat',
    'category': 'Budaya',
    'rating': '4.6',
    'reviews': '90 review',
    'image': 'assets/images/masjid_agung_tubaba.jpg',
    'description':
        'Masjid agung dengan desain arsitektur modern yang jadi landmark ikonik Kabupaten Tulang Bawang Barat.',
  },

  {
    'id': 'rm_khas_tubaba',
    'latitude': '-4.45',
    'longitude': '105.05',
    'name': 'RM Saung Tubaba',
    'location': 'Tulang Bawang Barat',
    'category': 'Kuliner',
    'rating': '4.1',
    'reviews': '35 review',
    'image': 'assets/images/rm_khas_tubaba.jpg',
    'description':
        'Rumah makan dengan menu khas Lampung di kawasan Panaragan Jaya, ibu kota Tulang Bawang Barat.',
  },

  {
    'id': 'agrowisata_tubaba',
    'latitude': '-4.50',
    'longitude': '105.10',
    'name': 'Kebun Buah Panaragan',
    'location': 'Tulang Bawang Barat',
    'category': 'Alam',
    'rating': '4.0',
    'reviews': '30 review',
    'image': 'assets/images/agrowisata_tubaba.jpg',
    'description':
        'Kawasan perkebunan buah di Panaragan yang dikembangkan sebagai agrowisata, menawarkan suasana pedesaan khas Tulang Bawang Barat.',
  },

  // WAY KANAN

  {
    'id': 'kopi_robusta_way_kanan',
    'latitude': '-4.45',
    'longitude': '104.60',
    'name': 'Kedai Kopi Baradatu',
    'location': 'Way Kanan',
    'category': 'Kuliner',
    'rating': '4.3',
    'reviews': '50 review',
    'image': 'assets/images/kopi_robusta_way_kanan.jpg',
    'description':
        'Kedai kopi di Baradatu yang menyajikan kopi robusta hasil perkebunan lokal Way Kanan, salah satu daerah penghasil kopi di Lampung.',
  },

  {
    'id': 'air_terjun_way_kanan',
    'latitude': '-4.50',
    'longitude': '104.55',
    'name': 'Air Terjun Curup Sanggi',
    'location': 'Way Kanan',
    'category': 'Alam',
    'rating': '4.2',
    'reviews': '40 review',
    'image': 'assets/images/air_terjun_way_kanan.jpg',
    'description':
        'Air terjun di kawasan perbukitan Way Kanan yang masih asri, cocok untuk wisata alam dan trekking ringan.',
  },

  {
    'id': 'taman_kota_blambangan_umpu',
    'latitude': '-4.55',
    'longitude': '104.50',
    'name': 'Taman Kota Blambangan Umpu',
    'location': 'Way Kanan',
    'category': 'Buatan',
    'rating': '4.0',
    'reviews': '30 review',
    'image': 'assets/images/taman_kota_blambangan_umpu.jpg',
    'description':
        'Taman kota di Blambangan Umpu, ibu kota Kabupaten Way Kanan, jadi ruang publik untuk bersantai warga sekitar.',
  },

  // MESUJI

  {
    'id': 'tambak_seafood_mesuji',
    'latitude': '-3.90',
    'longitude': '105.45',
    'name': 'RM Tambak Rawa Jaya',
    'location': 'Mesuji',
    'category': 'Kuliner',
    'rating': '4.0',
    'reviews': '25 review',
    'image': 'assets/images/tambak_seafood_mesuji.jpg',
    'description':
        'Warung makan yang menyajikan hasil tambak segar khas Mesuji, daerah yang dikenal dengan perikanan air payaunya.',
  },

  {
    'id': 'rawa_pesisir_mesuji',
    'latitude': '-3.95',
    'longitude': '105.50',
    'name': 'Rawa Bakung Mesuji',
    'location': 'Mesuji',
    'category': 'Alam',
    'rating': '3.9',
    'reviews': '20 review',
    'image': 'assets/images/rawa_pesisir_mesuji.jpg',
    'description':
        'Kawasan rawa dan pesisir di ujung utara Lampung yang menampilkan lanskap khas dataran rendah dan tambak.',
  },

  {
    'id': 'taman_kota_mesuji',
    'latitude': '-3.90',
    'longitude': '105.40',
    'name': 'Taman Kota Mesuji',
    'location': 'Mesuji',
    'category': 'Buatan',
    'rating': '4.0',
    'reviews': '20 review',
    'image': 'assets/images/taman_kota_mesuji.jpg',
    'description':
        'Taman kota sederhana di pusat pemerintahan Kabupaten Mesuji, jadi ruang publik warga setempat.',
  },

  // PESISIR BARAT

  {
    'id': 'pulau_pisang',
    'latitude': '-5.0333',
    'longitude': '103.85',
    'name': 'Pulau Pisang',
    'location': 'Pesisir Barat',
    'category': 'Alam',
    'rating': '4.6',
    'reviews': '150 review',
    'image': 'assets/images/pulau_pisang.jpg',
    'description':
        'Pulau kecil di lepas pantai Pesisir Barat dengan pantai berpasir putih, terumbu karang, dan suasana yang masih sangat tenang.',
  },

  {
    'id': 'pantai_labuhan_jukung',
    'latitude': '-5.1833',
    'longitude': '103.9333',
    'name': 'Pantai Labuhan Jukung',
    'location': 'Pesisir Barat',
    'category': 'Alam',
    'rating': '4.5',
    'reviews': '160 review',
    'image': 'assets/images/pantai_labuhan_jukung.jpg',
    'description':
        'Pantai populer di Krui dengan ombak yang juga diminati peselancar, serta pemandangan matahari terbenam yang jadi favorit wisatawan.',
  },

  {
    'id': 'rm_khas_krui',
    'latitude': '-5.18',
    'longitude': '103.94',
    'name': 'RM Seafood Labuhan Jukung',
    'location': 'Pesisir Barat',
    'category': 'Kuliner',
    'rating': '4.2',
    'reviews': '45 review',
    'image': 'assets/images/rm_khas_krui.jpg',
    'description':
        'Rumah makan seafood dekat Pantai Labuhan Jukung, Krui, jadi tempat singgah favorit wisatawan sebelum atau sesudah berselancar di Tanjung Setia.',
  },

];

// Galeri foto tambahan (opsional) untuk destinasi yang punya lebih
// dari 1 foto. Dikunci pakai 'id' supaya tetap valid walau nama
// destinasi berubah. Fallback ke foto utama kalau id tidak ada di sini.

const Map<String, List<String>> kDestinationGalleryImages = {
  'pulau_wayang': [
    'assets/images/pulau_wayang.jpg',
    'assets/images/pulau_wayang2.jpg',
    'assets/images/pulau_wayang3.jpg',
    'assets/images/pulau_wayang4.jpg',
  ],
};

// Lookup utama berdasarkan 'id' (bukan 'name', karena nama bisa
// berubah sedangkan id tidak).
Map<String, String>? findDestinationById(String id) {
  for (final destination in kDestinationsData) {
    if (destination['id'] == id) {
      return destination;
    }
  }

  return null;
}

// [DUMMY] Jam operasional diperkirakan per KATEGORI (format 24 jam),
// belum per destinasi. TODO(backend): ganti dengan field openHour/
// closeHour asli dari database.

class OperatingHours {
  final int openHour;
  final int closeHour;

  const OperatingHours({required this.openHour, required this.closeHour});
}

OperatingHours operatingHoursFor(Map<String, dynamic> destination) {
  final String category = (destination['category'] as String?) ?? 'Alam';

  switch (category) {
    case 'Kuliner':
      return const OperatingHours(openHour: 8, closeHour: 22);

    case 'Budaya':
      return const OperatingHours(openHour: 8, closeHour: 16);

    case 'Buatan':
      return const OperatingHours(openHour: 9, closeHour: 21);

    case 'Alam':
    default:
      return const OperatingHours(openHour: 6, closeHour: 18);
  }
}

// [DUMMY] Estimasi durasi kunjungan per kategori (jam). Samakan
// dengan label di _estimateDuration (ai_itinerary_screen.dart) supaya
// tidak beda dengan teks yang ditampilkan di UI.

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

// [DUMMY] Waktu tempuh dihitung dari jarak garis lurus (haversine)
// dibagi kecepatan rata-rata kendaraan, ditambah faktor kelokan jalan
// (+30%). TODO(backend): ganti dengan routing API sungguhan (mis.
// OSRM/Google Directions).

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

// Ambil koordinat (LatLng) dari satu entri destinasi.
LatLng? coordinateOfDestination(Map<String, dynamic> destination) {
  final double? lat =
      double.tryParse(destination['latitude']?.toString() ?? '');
  final double? lon =
      double.tryParse(destination['longitude']?.toString() ?? '');

  if (lat == null || lon == null) return null;

  return LatLng(lat, lon);
}

// Cari destinasi berdasarkan nama (legacy, untuk search bar). Untuk
// referensi di dalam kode, pakai findDestinationById.
Map<String, String>? findDestinationByName(String name) {
  final String normalizedName = name.trim().toLowerCase();

  for (final destination in kDestinationsData) {
    if (destination['name']!.toLowerCase() == normalizedName) {
      return destination;
    }
  }

  return null;
}

// Cocokkan 'location' destinasi dengan 'travelCity' (mis. "Kabupaten
// Pesawaran" vs "Pesawaran"). Location generik "Lampung" selalu cocok.
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

// Bounding box PERKIRAAN tiap kabupaten/kota di Lampung, dipakai untuk
// koordinat dummy/fallback (kDestinationsData, ManualScheduleScreen,
// ItineraryDetailScreen) -- bukan untuk akurasi geografis presisi.

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

// Dipisah jadi fungsi sendiri supaya bisa dipakai ulang oleh
// findRegencyBounds/coordinateForRegency tanpa duplikasi RegExp.
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

// Hasilkan LatLng acak di dalam bounding box kabupaten/kota yang
// diminta (fallback ke Bandar Lampung kalau nama tidak dikenali).
// `seed` opsional dipakai supaya hasilnya stabil untuk input yang sama.

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