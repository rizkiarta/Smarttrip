import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import '../services/destination_service.dart';


// Data destinasi bersama, dipakai oleh DestinationSelectionScreen dan
// AIItineraryScreen supaya keduanya mengacu ke daftar yang sama.
//
// 'latitude'/'longitude' masih perkiraan (dummy), bukan hasil geocoding
// presisi -- tapi tetap dijaga jatuh di kabupaten/kota yang sesuai
// dengan 'location'. Cek kLampungRegencyBounds kalau nambah destinasi
// baru.

const List<Map<String, String>> kDestinationsData = [
  // 1. Pesawaran
  {
    'id': 'pulau_pahawang',
    'name': 'Pulau Pahawang',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '340 ulasan',
    'image': 'assets/images/pulau_pahawang.jpg',
    'description': 'Surga snorkeling terkenal di Lampung dengan terumbu karang indah, ikan nemo, dan keindahan pulau pasir timbul.',
    'price': 'Rp 150.000 - Rp 300.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.6705',
    'longitude': '105.2241',
  },
  {
    'id': 'pulau_tegal_mas',
    'name': 'Pulau Tegal Mas',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '280 ulasan',
    'image': 'assets/images/pulau_tegal_mas.jpg',
    'description': 'Destinasi wisata pulau bergaya Maldives di Lampung dengan penginapan terapung dan spot snorkeling penyu.',
    'price': 'Rp 50.000 - Rp 150.000',
    'time': '07.00 - 18.00',
    'latitude': '-5.5841',
    'longitude': '105.2562',
  },
  {
    'id': 'pantai_sari_ringgung',
    'name': 'Pantai Sari Ringgung',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.5',
    'reviews': '210 ulasan',
    'image': 'assets/images/pantai_sari_ringgung.jpg',
    'description': 'Pantai keluarga populer dengan fenomena Pasir Timbul dan Masjid Terapung di tengah laut.',
    'price': 'Rp 20.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.5562',
    'longitude': '105.2341',
  },
  {
    'id': 'pantai_mutun',
    'name': 'Pantai Mutun',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.4',
    'reviews': '195 ulasan',
    'image': 'assets/images/pantai_mutun.jpg',
    'description': 'Pantai pasir putih terdekat dari kota Bandar Lampung, tempat ideal untuk rekreasi air dan menyeberang ke Pulau Tangkil.',
    'price': 'Rp 25.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.5181',
    'longitude': '105.2536',
  },
  {
    'id': 'pantai_klara',
    'name': 'Pantai Klara',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.6',
    'reviews': '180 ulasan',
    'image': 'assets/images/pantai_klara.jpg',
    'description': 'Singkatan Kelapa Rapat, pantai bernuansa rindang dengan ombak sangat tenang dan jajaran pohon kelapa.',
    'price': 'Rp 15.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.5789',
    'longitude': '105.2154',
  },
  {
    'id': 'pulau_wayang',
    'name': 'Pulau Wayang',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.9',
    'reviews': '150 ulasan',
    'image': 'assets/images/pulau_wayang.jpg',
    'description': 'Gugusan tebing batu menjulang tinggi mirip Raja Ampat di ujung selatan Pesawaran.',
    'price': 'Rp 350.000',
    'time': '06.00 - 17.00',
    'latitude': '-5.7335',
    'longitude': '105.2012',
  },
  {
    'id': 'teluk_hantu',
    'name': 'Teluk Hantu',
    'location': 'Pesawaran',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '95 ulasan',
    'image': 'assets/images/teluk_hantu.jpg',
    'description': 'Teluk tersembunyi dengan air laut jernih kehijauan dan pantai pasir putih yang belum terjamah di Punduh Pedada.',
    'price': 'Rp 10.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.6811',
    'longitude': '105.2285',
  },
  {
    'id': 'seafood_pesawaran',
    'name': 'RM Bahari Cempaka Mutun',
    'location': 'Pesawaran',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '110 ulasan',
    'image': 'assets/images/seafood_pesawaran.jpg',
    'description': 'Restoran seafood tepi pantai yang menyajikan cumi bakar, kerapu asam manis, dan kelapa muda segar.',
    'price': 'Rp 40.000 - Rp 120.000',
    'time': '09.00 - 21.00',
    'latitude': '-5.5191',
    'longitude': '105.2541',
  },

  // 2. Bandar Lampung
  {
    'id': 'museum_lampung',
    'name': 'Museum Lampung',
    'location': 'Bandar Lampung',
    'category': 'Budaya',
    'rating': '4.5',
    'reviews': '160 ulasan',
    'image': 'assets/images/museum_lampung.jpg',
    'description': 'Museum negeri tempat koleksi artefak budaya, kerajinan kain tapis, dan sejarah provinsi Lampung.',
    'price': 'Rp 5.000',
    'time': '08.00 - 15.00',
    'latitude': '-5.3721',
    'longitude': '105.2425',
  },
  {
    'id': 'puncak_mas',
    'name': 'Puncak Mas',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.6',
    'reviews': '240 ulasan',
    'image': 'assets/images/puncak_mas.jpg',
    'description': 'Taman wisata perbukitan di Sukadanaham dengan rumah pohon, sepeda gantung, dan pemandangan laut & kota.',
    'price': 'Rp 20.000',
    'time': '08.00 - 22.00',
    'latitude': '-5.4128',
    'longitude': '105.2274',
  },
  {
    'id': 'bukit_sakura_kemiling',
    'name': 'Bukit Sakura Kemiling',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.4',
    'reviews': '130 ulasan',
    'image': 'assets/images/bukit_sakura_kemiling.jpg',
    'description': 'Destinasi wisata keluarga bertema taman Jepang lengkap dengan persewaan baju kimono dan ornamen bunga sakura.',
    'price': 'Rp 15.000',
    'time': '08.00 - 21.00',
    'latitude': '-5.3995',
    'longitude': '105.2281',
  },
  {
    'id': 'lembah_hijau',
    'name': 'Lembah Hijau',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.5',
    'reviews': '310 ulasan',
    'image': 'assets/images/lembah_hijau.jpg',
    'description': 'Taman rekreasi keluarga terpadu yang memadukan waterboom, taman satwa, outbond, dan penginapan.',
    'price': 'Rp 25.000 - Rp 50.000',
    'time': '08.00 - 17.00',
    'latitude': '-5.4215',
    'longitude': '105.2341',
  },
  {
    'id': 'trans_studio_mini_lampung',
    'name': 'Trans Studio Mini Lampung',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.6',
    'reviews': '270 ulasan',
    'image': 'assets/images/trans_studio_mini_lampung.jpg',
    'description': 'Taman bermain indoor modern dengan berbagai wahana permainan seru untuk anak-anak hingga dewasa di Transmart.',
    'price': 'Rp 50.000 - Rp 200.000',
    'time': '10.00 - 21.00',
    'latitude': '-5.3855',
    'longitude': '105.2751',
  },
  {
    'id': 'taman_budaya_lampung',
    'name': 'Taman Budaya Lampung',
    'location': 'Bandar Lampung',
    'category': 'Budaya',
    'rating': '4.3',
    'reviews': '85 ulasan',
    'image': 'assets/images/taman_budaya_lampung.jpg',
    'description': 'Pusat pertunjukan seni, pameran lukisan, pertunjukan teater, dan pelestarian kebudayaan Lampung.',
    'price': 'Gratis',
    'time': '08.00 - 16.00',
    'latitude': '-5.4278',
    'longitude': '105.2562',
  },
  {
    'id': 'pantai_puri_gading',
    'name': 'Pantai Puri Gading',
    'location': 'Bandar Lampung',
    'category': 'Alam',
    'rating': '4.2',
    'reviews': '75 ulasan',
    'image': 'assets/images/pantai_puri_gading.jpg',
    'description': 'Pantai pesisir di Teluk Betung dengan pemandangan kapal melintas dan gazebo santai tepi pantai.',
    'price': 'Rp 10.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.4562',
    'longitude': '105.2471',
  },
  {
    'id': 'navara_city_park',
    'name': 'Navara City Park',
    'location': 'Bandar Lampung',
    'category': 'Buatan',
    'rating': '4.5',
    'reviews': '90 ulasan',
    'image': 'assets/images/navara_city_park.jpg',
    'description': 'Taman kota baru bertema lanskap hijau modern dengan area kuliner outdoor dan spot santai keluarga di Kemiling.',
    'price': 'Rp 10.000',
    'time': '09.00 - 21.00',
    'latitude': '-5.3951',
    'longitude': '105.2185',
  },
  {
    'id': 'mie_khodon',
    'name': 'Mie Khodon',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.7',
    'reviews': '450 ulasan',
    'image': 'assets/images/mie_khodon.jpg',
    'description': 'Kuliner legendaris mie goreng & mie rebus khas Lampung bertekstur tebal sejak 1960 di Teluk Betung.',
    'price': 'Rp 20.000 - Rp 35.000',
    'time': '13.00 - 19.00',
    'latitude': '-5.4418',
    'longitude': '105.2635',
  },
  {
    'id': 'seruit_khas_lampung',
    'name': 'RM Seruit Mendanau',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.8',
    'reviews': '380 ulasan',
    'image': 'assets/images/seruit_khas_lampung.jpg',
    'description': 'Restoran khas masakan tradisional Lampung dengan hidangan utama Seruit (ikan bakar/rebus, sambal terasi & tempoyak).',
    'price': 'Rp 30.000 - Rp 75.000',
    'time': '09.00 - 21.00',
    'latitude': '-5.4182',
    'longitude': '105.2561',
  },
  {
    'id': 'cafe_1',
    'name': 'Kedai Senja Sultan Agung',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '140 ulasan',
    'image': 'assets/images/kedai_senja_sultan_agung.jpg',
    'description': 'Place nongkrong kopi outdoor favorit anak muda Bandar Lampung dengan live music dan camilan kekinian.',
    'price': 'Rp 15.000 - Rp 45.000',
    'time': '15.00 - 23.00',
    'latitude': '-5.3912',
    'longitude': '105.2654',
  },
  {
    'id': 'cafe_2',
    'name': 'Cafe Rumah Kayu',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.7',
    'reviews': '520 ulasan',
    'image': 'assets/images/cafe_rumah_kayu.jpg',
    'description': 'Restoran keluarga dengan saung-saung di atas kolam, interior nuansa kayu asri, dan sajian seafood komplit.',
    'price': 'Rp 50.000 - Rp 150.000',
    'time': '10.00 - 22.00',
    'latitude': '-5.3855',
    'longitude': '105.2751',
  },
  {
    'id': 'resto_1',
    'name': 'RM Saung Kito Enggal',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '210 ulasan',
    'image': 'assets/images/rm_saung_kito_enggal.jpg',
    'description': 'Restoran bernuansa lesehan Sunda-Lampung yang menyajikan gurame terbang, bebek goreng, dan sambal jos.',
    'price': 'Rp 25.000 - Rp 80.000',
    'time': '10.00 - 21.30',
    'latitude': '-5.4121',
    'longitude': '105.2588',
  },
  {
    'id': 'resto_2',
    'name': 'RM Pondok Rasa Kedaton',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '190 ulasan',
    'image': 'assets/images/rm_pondok_rasa_kedaton.jpg',
    'description': 'Rumah makan prasmanan dengan aneka olahan ikan mas, pindang patin, dan masakan khas rumahan.',
    'price': 'Rp 20.000 - Rp 50.000',
    'time': '09.00 - 21.00',
    'latitude': '-5.3789',
    'longitude': '105.2552',
  },
  {
    'id': 'kedai_kopi_robusta_lampung',
    'name': 'Kedai Kopi Robusta Lampung',
    'location': 'Bandar Lampung',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '175 ulasan',
    'image': 'assets/images/kedai_kopi_robusta_lampung.jpg',
    'description': 'Warung kopi khas olahan biji kopi pilihan Robusta Lampung asli dengan aroma pekat bermutu tinggi.',
    'price': 'Rp 12.000 - Rp 30.000',
    'time': '08.00 - 23.00',
    'latitude': '-5.3882',
    'longitude': '105.2691',
  },

  // 3. Lampung Selatan
  {
    'id': 'anak_krakatau',
    'name': 'Anak Krakatau',
    'location': 'Lampung Selatan',
    'category': 'Alam',
    'rating': '4.9',
    'reviews': '410 ulasan',
    'image': 'assets/images/anak_krakatau.jpg',
    'description': 'Gunung berapi aktif legendaris di Selat Sunda dengan pesona eksotis medan vulkanik dan keanekaragaman bahari.',
    'price': 'Rp 500.000 - Rp 1.500.000',
    'time': '06.00 - 17.00',
    'latitude': '-6.1022',
    'longitude': '105.4231',
  },
  {
    'id': 'siger',
    'name': 'Menara Siger',
    'location': 'Lampung Selatan',
    'category': 'Budaya',
    'rating': '4.6',
    'reviews': '530 ulasan',
    'image': 'assets/images/menara_siger.jpg',
    'description': 'Ikon kebanggaan Lampung berbentuk mahkota Siger emas di atas bukit Bakauheni, titik nol gerbang pulau Sumatra.',
    'price': 'Rp 10.000',
    'time': '06.00 - 20.00',
    'latitude': '-5.8715',
    'longitude': '105.7554',
  },
  {
    'id': 'pantai_kyokko',
    'name': 'Pantai Kyokko',
    'location': 'Lampung Selatan',
    'category': 'Alam',
    'rating': '4.5',
    'reviews': '120 ulasan',
    'image': 'assets/images/pantai_kyokko.jpg',
    'description': 'Pantai indah dengan latar belakang pemandangan Gunung Rajabasa dan hamparan pasir halus di Rajabasa Kalianda.',
    'price': 'Rp 15.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.6881',
    'longitude': '105.5786',
  },
  {
    'id': 'seafood_kalianda',
    'name': 'RM Seafood Dermaga Canti',
    'location': 'Lampung Selatan',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '145 ulasan',
    'image': 'assets/images/seafood_kalianda.jpg',
    'description': 'Rumah makan di dekat dermaga penyeberangan Canti yang terkenal dengan masakan ikan simba bakar dan sambal mentah.',
    'price': 'Rp 35.000 - Rp 90.000',
    'time': '08.00 - 21.00',
    'latitude': '-5.6982',
    'longitude': '105.5791',
  },

  // 4. Tanggamus
  {
    'id': 'pantai_gigi_hiu',
    'name': 'Pantai Gigi Hiu',
    'location': 'Tanggamus',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '290 ulasan',
    'image': 'assets/images/pantai_gigi_hiu.jpg',
    'description': 'Pantai fenomena batu karang tajam menjulang menyerupai gigi hiu di Kelumbayan, favorit fotografer dunia.',
    'price': 'Rp 15.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.7541',
    'longitude': '105.0562',
  },
  {
    'id': 'teluk_kiluan',
    'name': 'Teluk Kiluan',
    'location': 'Tanggamus',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '360 ulasan',
    'image': 'assets/images/teluk_kiluan.jpg',
    'description': 'Destinasi laut populer untuk melihat atraksi lumba-lumba bebas di samudra dan laguna laut Kolam Laguna.',
    'price': 'Rp 250.000',
    'time': '06.00 - 17.00',
    'latitude': '-5.7725',
    'longitude': '105.1051',
  },
  {
    'id': 'air_terjun_way_lalaan',
    'name': 'Air Terjun Way Lalaan',
    'location': 'Tanggamus',
    'category': 'Alam',
    'rating': '4.5',
    'reviews': '170 ulasan',
    'image': 'assets/images/way_lalaan.jpg',
    'description': 'Air terjun bertingkat di kaki Gunung Tanggamus yang sudah dikenal sejak zaman kolonial Belanda.',
    'price': 'Rp 10.000',
    'time': '07.00 - 17.00',
    'latitude': '-5.4741',
    'longitude': '104.6285',
  },
  {
    'id': 'waduk_batutegi',
    'name': 'Waduk Batutegi',
    'location': 'Tanggamus',
    'category': 'Buatan',
    'rating': '4.6',
    'reviews': '140 ulasan',
    'image': 'assets/images/waduk_batutegi.jpg',
    'description': 'Bendungan terbesar di Asia Tenggara yang dikelilingi perbukitan hijau asri dan perahu wisata di Air Naningan.',
    'price': 'Rp 10.000',
    'time': '08.00 - 17.00',
    'latitude': '-5.2718',
    'longitude': '104.6985',
  },
  {
    'id': 'seafood_kota_agung',
    'name': 'RM Seafood Teluk Semaka',
    'location': 'Tanggamus',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '95 ulasan',
    'image': 'assets/images/seafood_kota_agung.jpg',
    'description': 'Warung makan ikan segar khas pesisir Kota Agung dengan sajian udang bakar dan bumbu kuning khas Tanggamus.',
    'price': 'Rp 30.000 - Rp 80.000',
    'time': '09.00 - 21.00',
    'latitude': '-5.4981',
    'longitude': '104.6152',
  },

  // 5. Lampung Barat & Pesisir Barat
  {
    'id': 'danau_ranau',
    'name': 'Danau Ranau',
    'location': 'Lampung Barat',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '310 ulasan',
    'image': 'assets/images/danau_ranau.jpg',
    'description': 'Danau vulkanik terbesar kedua di Sumatra dengan latar Gunung Seminung yang sejuk dan pemandian air panas.',
    'price': 'Rp 10.000',
    'time': '06.00 - 18.00',
    'latitude': '-4.8794',
    'longitude': '103.9313',
  },
  {
    'id': 'danau_suoh',
    'name': 'Danau Suoh',
    'location': 'Lampung Barat',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '180 ulasan',
    'image': 'assets/images/danau_suoh.jpg',
    'description': 'Kawasan geothermal ajaib di Lampung Barat dengan 4 danau unik yang dapat berubah warna dan pasir kuning.',
    'price': 'Rp 15.000',
    'time': '07.00 - 17.00',
    'latitude': '-5.2381',
    'longitude': '104.2642',
  },
  {
    'id': 'kopi_liwa',
    'name': 'Kedai Kopi Robusta Liwa',
    'location': 'Lampung Barat',
    'category': 'Kuliner',
    'rating': '4.7',
    'reviews': '130 ulasan',
    'image': 'assets/images/kopi_liwa.jpg',
    'description': 'Kedai kopi khas dataran tinggi Liwa yang menyajikan kopi luwak & kopi hitam cita rasa petik merah.',
    'price': 'Rp 15.000 - Rp 40.000',
    'time': '08.00 - 22.00',
    'latitude': '-5.0351',
    'longitude': '104.0921',
  },
  {
    'id': 'skala_brak_lamban_balak',
    'name': 'Kompleks Adat Skala Brak',
    'location': 'Lampung Barat',
    'category': 'Budaya',
    'rating': '4.6',
    'reviews': '95 ulasan',
    'image': 'assets/images/skala_brak_lamban_balak.jpg',
    'description': 'Rumah adat Lamban Balak dan pusat peradaban leluhur asal usul suku bangsa Lampung di Batu Brak.',
    'price': 'Gratis / Donasi',
    'time': '08.00 - 16.00',
    'latitude': '-5.0682',
    'longitude': '104.0815',
  },
  {
    'id': 'pantai_labuhan_jukung',
    'name': 'Pantai Labuhan Jukung',
    'location': 'Pesisir Barat',
    'category': 'Alam',
    'rating': '4.7',
    'reviews': '280 ulasan',
    'image': 'assets/images/pantai_labuhan_jukung.jpg',
    'description': 'Pantai ikonik ibu kota Krui dengan pemandangan sunset memukau, ombak selancar, dan spot kuliner malam.',
    'price': 'Rp 5.000',
    'time': '06.00 - 22.00',
    'latitude': '-5.1915',
    'longitude': '103.9281',
  },
  {
    'id': 'pantai_tanjung_setia',
    'name': 'Pantai Tanjung Setia',
    'location': 'Pesisir Barat',
    'category': 'Alam',
    'rating': '4.9',
    'reviews': '390 ulasan',
    'image': 'assets/images/pantai_tanjung_setia.jpg',
    'description': 'Surga selancar dunia di Pesisir Barat tempat kompetisi WSL Krui Pro dengan ombak kelas internasional.',
    'price': 'Rp 10.000',
    'time': '06.00 - 18.00',
    'latitude': '-5.3112',
    'longitude': '103.9025',
  },
  {
    'id': 'pulau_pisang',
    'name': 'Pulau Pisang',
    'location': 'Pesisir Barat',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '160 ulasan',
    'image': 'assets/images/pulau_pisang.jpg',
    'description': 'Pulau kecil eksotis lepas pantai Krui dengan rumah panggung tua bersejarah, lumba-lumba, dan pasir putih.',
    'price': 'Rp 30.000 (Perahu)',
    'time': '06.00 - 17.00',
    'latitude': '-5.1125',
    'longitude': '103.8412',
  },
  {
    'id': 'rm_khas_krui',
    'name': 'RM Seafood Labuhan Jukung',
    'location': 'Pesisir Barat',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '115 ulasan',
    'image': 'assets/images/rm_khas_krui.jpg',
    'description': 'Rumah makan khas Krui yang terkenal dengan olahan ikan tatsu, gurita bakar, dan gulai taboh masakan pesisir.',
    'price': 'Rp 30.000 - Rp 85.000',
    'time': '09.00 - 21.00',
    'latitude': '-5.1925',
    'longitude': '103.9302',
  },

  // 6. Lampung Tengah & Metro
  {
    'id': 'air_terjun_curug_tujuh',
    'name': 'Air Terjun Curug Tujuh',
    'location': 'Lampung Tengah',
    'category': 'Alam',
    'rating': '4.6',
    'reviews': '140 ulasan',
    'image': 'assets/images/curug_tujuh.jpg',
    'description': 'Air terjun eksotis 7 tingkat yang berada di tengah kawasan hutan lindung Sendang Agung Lampung Tengah.',
    'price': 'Rp 10.000',
    'time': '07.00 - 16.00',
    'latitude': '-5.0211',
    'longitude': '104.9125',
  },
  {
    'id': 'air_terjun_curup',
    'name': 'Air Terjun Curup Lestari',
    'location': 'Lampung Tengah',
    'category': 'Alam',
    'rating': '4.4',
    'reviews': '95 ulasan',
    'image': 'assets/images/air_terjun_curup.jpg',
    'description': 'Air terjun alami dengan kolam bening yang dikelilingi pepohonan rindang di Pubian.',
    'price': 'Rp 5.000',
    'time': '07.00 - 17.00',
    'latitude': '-4.9125',
    'longitude': '104.9812',
  },
  {
    'id': 'danau_tirta_gangga',
    'name': 'Danau Tirta Gangga',
    'location': 'Lampung Tengah',
    'category': 'Budaya',
    'rating': '4.5',
    'reviews': '125 ulasan',
    'image': 'assets/images/danau_tirta_gangga.jpg',
    'description': 'Danau buatan bernuansa pura Bali di Seputih Banyak, lengkap dengan patung Bima dan Pura Tepi Danau.',
    'price': 'Rp 10.000',
    'time': '07.00 - 18.00',
    'latitude': '-4.8985',
    'longitude': '105.4125',
  },
  {
    'id': 'islamic_center_lampung_tengah',
    'name': 'Islamic Center Lampung Tengah',
    'location': 'Lampung Tengah',
    'category': 'Buatan',
    'rating': '4.6',
    'reviews': '200 ulasan',
    'image': 'assets/images/islamic_center_lampung_tengah.jpg',
    'description': 'Masjid megah kebanggaan warga Gunung Sugih dengan arsitektur memukau dan taman ruang terbuka publik.',
    'price': 'Gratis',
    'time': '04.00 - 21.00',
    'latitude': '-4.9652',
    'longitude': '105.2151',
  },
  {
    'id': 'pindang_sehat_gunung_sugih',
    'name': 'Pindang Sehat Gunung Sugih',
    'location': 'Lampung Tengah',
    'category': 'Kuliner',
    'rating': '4.7',
    'reviews': '230 ulasan',
    'image': 'assets/images/pindang_sehat_gunung_sugih.jpg',
    'description': 'Pusat kuliner pindang baung & patin kuah pegagan asam pedas segar di Gunung Sugih.',
    'price': 'Rp 35.000 - Rp 70.000',
    'time': '09.00 - 20.00',
    'latitude': '-4.9621',
    'longitude': '105.2162',
  },
  {
    'id': 'angkringan_jemelik',
    'name': 'Angkringan Jemelik',
    'location': 'Lampung Tengah',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '110 ulasan',
    'image': 'assets/images/angkringan_jemelik.jpg',
    'description': 'Tempat santai malam favorit warga Bandar Jaya dengan sajian nasi kucing, sate-satean, dan wedang ronde.',
    'price': 'Rp 5.000 - Rp 25.000',
    'time': '16.00 - 23.30',
    'latitude': '-4.9182',
    'longitude': '105.2125',
  },
  {
    'id': 'taman_merdeka_metro',
    'name': 'Taman Merdeka Metro',
    'location': 'Metro',
    'category': 'Buatan',
    'rating': '4.6',
    'reviews': '310 ulasan',
    'image': 'assets/images/taman_merdeka_metro.jpg',
    'description': 'Alun-alun pusat Kota Metro dengan tugu menara air kuno Belanda, area bermain, dan pusat kuliner malam.',
    'price': 'Gratis',
    'time': '06.00 - 23.00',
    'latitude': '-5.1138',
    'longitude': '105.3068',
  },
  {
    'id': 'islamic_center_metro',
    'name': 'Islamic Center Kota Metro',
    'location': 'Metro',
    'category': 'Budaya',
    'rating': '4.7',
    'reviews': '280 ulasan',
    'image': 'assets/images/islamic_center_metro.jpg',
    'description': 'Masjid Agung At-Taqwa Kota Metro dengan kubah emas besar di jantung kota.',
    'price': 'Gratis',
    'time': '04.00 - 21.00',
    'latitude': '-5.1132',
    'longitude': '105.3061',
  },
  {
    'id': 'angkringan_metro',
    'name': 'Angkringan Kamboja Metro',
    'location': 'Metro',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '150 ulasan',
    'image': 'assets/images/angkringan_metro.jpg',
    'description': 'Angkringan populer di Metro dengan suasana outdoor kekinian dan beragam pilihan sate usus & bakar-bakaran.',
    'price': 'Rp 8.000 - Rp 25.000',
    'time': '16.30 - 23.00',
    'latitude': '-5.1152',
    'longitude': '105.3082',
  },

  // 7. Pringsewu & Lampung Timur
  {
    'id': 'tugu_bambu_pringsewu',
    'name': 'Tugu Bambu Pringsewu',
    'location': 'Pringsewu',
    'category': 'Buatan',
    'rating': '4.5',
    'reviews': '180 ulasan',
    'image': 'assets/images/tugu_bambu_pringsewu.jpg',
    'description': 'Landmark gerbang utama Pringsewu bertema replika rerimbunan bambu bertingkat.',
    'price': 'Gratis',
    'time': '24 Jam',
    'latitude': '-5.3591',
    'longitude': '104.9734',
  },
  {
    'id': 'pendopo_pringsewu',
    'name': 'Pendopo Pringsewu',
    'location': 'Pringsewu',
    'category': 'Budaya',
    'rating': '4.6',
    'reviews': '220 ulasan',
    'image': 'assets/images/pendopo_pringsewu.jpg',
    'description': 'Ruang terbuka hijau dan alun-alun utama kabupaten Pringsewu untuk rekreasi dan acara budaya.',
    'price': 'Gratis',
    'time': '06.00 - 22.00',
    'latitude': '-5.3582',
    'longitude': '104.9741',
  },
  {
    'id': 'rm_khas_pringsewu',
    'name': 'RM Sinar Pringsewu',
    'location': 'Pringsewu',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '165 ulasan',
    'image': 'assets/images/rm_khas_pringsewu.jpg',
    'description': 'Rumah makan populer khas masakan Jawa-Lampung dengan keunggulan ayam bakar madu & gudeg.',
    'price': 'Rp 20.000 - Rp 60.000',
    'time': '08.00 - 21.00',
    'latitude': '-5.3615',
    'longitude': '104.9722',
  },
  {
    'id': 'taman_nasional_way_kambas',
    'name': 'Taman Nasional Way Kambas',
    'location': 'Lampung Timur',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '480 ulasan',
    'image': 'assets/images/way_kambas.jpg',
    'description': 'Pusat konservasi gajah Sumatra legendaris dan suaka rhino (badak) terbesar di Indonesia.',
    'price': 'Rp 20.000 - Rp 50.000',
    'time': '08.00 - 16.00',
    'latitude': '-5.0542',
    'longitude': '105.7481',
  },
  {
    'id': 'situs_purbakala_pugung_raharjo',
    'name': 'Situs Purbakala Pugung Raharjo',
    'location': 'Lampung Timur',
    'category': 'Budaya',
    'rating': '4.6',
    'reviews': '140 ulasan',
    'image': 'assets/images/situs_purbakala_pugung_raharjo.jpg',
    'description': 'Taman purbakala kuno peninggalan era Megalitikum berupa punden berundak dan benteng tanah di Sekampung Udik.',
    'price': 'Rp 5.000',
    'time': '08.00 - 16.00',
    'latitude': '-5.3085',
    'longitude': '105.5742',
  },
  {
    'id': 'rm_khas_sekampung',
    'name': 'RM Pondok Sekampung Asri',
    'location': 'Lampung Timur',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '105 ulasan',
    'image': 'assets/images/rm_khas_sekampung.jpg',
    'description': 'Rumah makan di tepi persawahan Sekampung yang menyajikan olahan ikan gurame dan es kelapa muda.',
    'price': 'Rp 25.000 - Rp 65.000',
    'time': '09.00 - 20.00',
    'latitude': '-5.1852',
    'longitude': '105.4851',
  },

  // 8. Lampung Utara & Way Kanan
  {
    'id': 'tugu_macan_kotabumi',
    'name': 'Tugu Macan Kotabumi',
    'location': 'Lampung Utara',
    'category': 'Buatan',
    'rating': '4.4',
    'reviews': '110 ulasan',
    'image': 'assets/images/tugu_macan_kotabumi.jpg',
    'description': 'Tugu simbolik landmark kota Kotabumi dengan patung macan emas di persimpangan utama.',
    'price': 'Gratis',
    'time': '24 Jam',
    'latitude': '-4.8268',
    'longitude': '104.9034',
  },
  {
    'id': 'agrowisata_lampung_utara',
    'name': 'Agrowisata Kebun Kopi Abung',
    'location': 'Lampung Utara',
    'category': 'Alam',
    'rating': '4.5',
    'reviews': '80 ulasan',
    'image': 'assets/images/agrowisata_lampung_utara.jpg',
    'description': 'Perkebunan kopi perbukitan di Abung Barat dengan fasilitas pemetikan kopi dan edukasi pengolahan.',
    'price': 'Rp 15.000',
    'time': '08.00 - 16.30',
    'latitude': '-4.8612',
    'longitude': '104.8512',
  },
  {
    'id': 'rm_khas_kotabumi',
    'name': 'RM Durian Asli Kotabumi',
    'location': 'Lampung Utara',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '135 ulasan',
    'image': 'assets/images/rm_khas_kotabumi.jpg',
    'description': 'Pusat kuliner durian lokal petik pohon & olahan tempoyak ikan baung khas Kotabumi.',
    'price': 'Rp 20.000 - Rp 80.000',
    'time': '09.00 - 21.00',
    'latitude': '-4.8291',
    'longitude': '104.8981',
  },
  {
    'id': 'taman_kota_blambangan_umpu',
    'name': 'Taman Kota Blambangan Umpu',
    'location': 'Way Kanan',
    'category': 'Buatan',
    'rating': '4.4',
    'reviews': '90 ulasan',
    'image': 'assets/images/taman_kota_blambangan_umpu.jpg',
    'description': 'Taman hijau pusat pemerintahan Blambangan Umpu dengan lapangan olahraga dan pepohonan rindang.',
    'price': 'Gratis',
    'time': '06.00 - 21.00',
    'latitude': '-4.4981',
    'longitude': '104.5162',
  },
  {
    'id': 'air_terjun_way_kanan',
    'name': 'Air Terjun Curup Gangsa',
    'location': 'Way Kanan',
    'category': 'Alam',
    'rating': '4.8',
    'reviews': '210 ulasan',
    'image': 'assets/images/air_terjun_way_kanan.jpg',
    'description': 'Air terjun megah menyerupai Niagara mini di Kasui Way Kanan dengan tebing batu lebar bergemuruh.',
    'price': 'Rp 10.000',
    'time': '07.00 - 17.00',
    'latitude': '-4.6281',
    'longitude': '104.3812',
  },
  {
    'id': 'kopi_robusta_way_kanan',
    'name': 'Kedai Kopi Baradatu',
    'location': 'Way Kanan',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '85 ulasan',
    'image': 'assets/images/kopi_robusta_way_kanan.jpg',
    'description': 'Kedai santai menyajikan kopi Robusta Baradatu racikan tradisional dan pisang goreng keju.',
    'price': 'Rp 10.000 - Rp 25.000',
    'time': '08.00 - 22.00',
    'latitude': '-4.5125',
    'longitude': '104.6152',
  },

  // 9. Tulang Bawang & Tulang Bawang Barat
  {
    'id': 'masjid_agung_tubaba',
    'name': 'Masjid Agung Tulang Bawang Barat',
    'location': 'Tulang Bawang Barat',
    'category': 'Budaya',
    'rating': '4.9',
    'reviews': '450 ulasan',
    'image': 'assets/images/masjid_agung_tubaba.jpg',
    'description': 'Masjid 99 Cahaya bertema arsitektur kontemporer tanpa kubah tradisional di Kompleks Dunia Islam Tubaba.',
    'price': 'Gratis',
    'time': '04.00 - 21.00',
    'latitude': '-4.4539',
    'longitude': '105.0601',
  },
  {
    'id': 'agrowisata_tubaba',
    'name': 'Kebun Buah Panaragan',
    'location': 'Tulang Bawang Barat',
    'category': 'Alam',
    'rating': '4.5',
    'reviews': '110 ulasan',
    'image': 'assets/images/agrowisata_tubaba.jpg',
    'description': 'Taman agrowisata buah naga dan kelengkeng petik sendiri di Panaragan Jaya.',
    'price': 'Rp 10.000',
    'time': '08.00 - 17.00',
    'latitude': '-4.4621',
    'longitude': '105.0712',
  },
  {
    'id': 'rm_khas_tubaba',
    'name': 'RM Saung Tubaba',
    'location': 'Tulang Bawang Barat',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '130 ulasan',
    'image': 'assets/images/rm_khas_tubaba.jpg',
    'description': 'Restoran kayu khas Panaragan yang menyajikan lalapan belut, pindang jelabat, dan es campur.',
    'price': 'Rp 25.000 - Rp 70.000',
    'time': '09.00 - 21.00',
    'latitude': '-4.4561',
    'longitude': '105.0582',
  },
  {
    'id': 'tepian_way_tulang_bawang',
    'name': 'Dermaga Rakyat Tulang Bawang',
    'location': 'Tulang Bawang',
    'category': 'Alam',
    'rating': '4.4',
    'reviews': '95 ulasan',
    'image': 'assets/images/tepian_way_tulang_bawang.jpg',
    'description': 'Tepi sungai Way Tulang Bawang di Menggala tempat pemandangan perahu kayu tradisional dan sunset.',
    'price': 'Gratis',
    'time': '06.00 - 18.00',
    'latitude': '-4.2612',
    'longitude': '105.2415',
  },
  {
    'id': 'rm_khas_menggala',
    'name': 'RM Tepian Menggala',
    'location': 'Tulang Bawang',
    'category': 'Kuliner',
    'rating': '4.6',
    'reviews': '140 ulasan',
    'image': 'assets/images/rm_khas_menggala.jpg',
    'description': 'Kuliner khas Menggala olahan udang galah sungai Way Tulang Bawang dan pindang patin.',
    'price': 'Rp 40.000 - Rp 100.000',
    'time': '09.00 - 21.00',
    'latitude': '-4.2651',
    'longitude': '105.2452',
  },
  {
    'id': 'wisata_alam_21',
    'name': 'Wisata Alam 21',
    'location': 'Tulang Bawang',
    'category': 'Buatan',
    'rating': '4.3',
    'reviews': '75 ulasan',
    'image': 'assets/images/wisata_alam_21.jpg',
    'description': 'Taman rekreasi buatan dengan kolam renang dan spot foto selfie di Banjar Margo.',
    'price': 'Rp 15.000',
    'time': '08.00 - 17.00',
    'latitude': '-4.3125',
    'longitude': '105.3152',
  },

  // 10. Mesuji
  {
    'id': 'taman_kota_mesuji',
    'name': 'Taman Kota Mesuji',
    'location': 'Mesuji',
    'category': 'Buatan',
    'rating': '4.3',
    'reviews': '70 ulasan',
    'image': 'assets/images/taman_kota_mesuji.jpg',
    'description': 'Taman kota Simpang Pematang untuk area olahraga warga dan bermain anak.',
    'price': 'Gratis',
    'time': '06.00 - 21.00',
    'latitude': '-4.0152',
    'longitude': '105.4125',
  },
  {
    'id': 'rawa_pesisir_mesuji',
    'name': 'Rawa Bakung Mesuji',
    'location': 'Mesuji',
    'category': 'Alam',
    'rating': '4.4',
    'reviews': '65 ulasan',
    'image': 'assets/images/rawa_pesisir_mesuji.jpg',
    'description': 'Lanskap rawa luas alami di kabupaten Mesuji tempat habitat burung rawa dan memancing.',
    'price': 'Gratis',
    'time': '06.00 - 17.00',
    'latitude': '-3.9851',
    'longitude': '105.4852',
  },
  {
    'id': 'tambak_seafood_mesuji',
    'name': 'RM Tambak Rawa Jaya',
    'location': 'Mesuji',
    'category': 'Kuliner',
    'rating': '4.5',
    'reviews': '80 ulasan',
    'image': 'assets/images/tambak_seafood_mesuji.jpg',
    'description': 'Rumah makan ikan bakar tawar (gabus, nila, patin) hasil tangkapan segar rawa Mesuji.',
    'price': 'Rp 20.000 - Rp 50.000',
    'time': '09.00 - 20.00',
    'latitude': '-4.0212',
    'longitude': '105.4215',
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
  final liveList = DestinationService.instance.destinations.value;
  if (liveList.isNotEmpty) {
    for (final d in liveList) {
      if (d.id == id) {
        return d.toDisplayMap();
      }
    }
  }

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
  // 1. Coba baca koordinat langsung dari map (berbagai kunci penamaan)
  double? lat = double.tryParse(destination['latitude']?.toString() ?? '');
  lat ??= double.tryParse(destination['lat']?.toString() ?? '');

  double? lon = double.tryParse(destination['longitude']?.toString() ?? '');
  lon ??= double.tryParse(destination['lng']?.toString() ?? '');
  lon ??= double.tryParse(destination['lon']?.toString() ?? '');

  // Jika koordinat valid dan bukan 0,0 (di samudra)
  if (lat != null && lon != null && (lat.abs() > 0.001 || lon.abs() > 0.001)) {
    return LatLng(lat, lon);
  }

  // 2. Lookup berdasarkan ID destinasi dari DestinationService/Database
  final String? id = destination['destination_id']?.toString() ?? destination['id']?.toString();
  if (id != null && id.isNotEmpty) {
    final foundById = findDestinationById(id);
    if (foundById != null) {
      final double? foundLat = double.tryParse(foundById['latitude']?.toString() ?? '');
      final double? foundLon = double.tryParse(foundById['longitude']?.toString() ?? '');
      if (foundLat != null && foundLon != null && (foundLat.abs() > 0.001 || foundLon.abs() > 0.001)) {
        return LatLng(foundLat, foundLon);
      }
    }
  }

  // 3. Lookup berdasarkan nama destinasi
  final String? name = destination['destination_name']?.toString() ??
      destination['name']?.toString() ??
      destination['placeName']?.toString();
  if (name != null && name.isNotEmpty) {
    final foundByName = findDestinationByName(name);
    if (foundByName != null) {
      final double? foundLat = double.tryParse(foundByName['latitude']?.toString() ?? '');
      final double? foundLon = double.tryParse(foundByName['longitude']?.toString() ?? '');
      if (foundLat != null && foundLon != null && (foundLat.abs() > 0.001 || foundLon.abs() > 0.001)) {
        return LatLng(foundLat, foundLon);
      }
    }
  }

  // 4. Fallback lokasi wilayah (misal: "Bandar Lampung", "Pesawaran", "Lampung")
  final String location = (destination['location'] ??
          destination['city'] ??
          destination['destinationCity'] ??
          destination['address'] ??
          'bandar lampung')
      .toString();

  return coordinateForRegency(location, seed: name ?? id ?? location);
}

// Cari destinasi berdasarkan nama (legacy, untuk search bar). Untuk
// referensi di dalam kode, pakai findDestinationById.
Map<String, String>? findDestinationByName(String name) {
  final String normalizedName = name.trim().toLowerCase();
  final liveList = DestinationService.instance.destinations.value;
  if (liveList.isNotEmpty) {
    for (final d in liveList) {
      if (d.name.trim().toLowerCase() == normalizedName) {
        return d.toDisplayMap();
      }
    }
  }

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

  if (normalizedCity == 'lampung' ||
      normalizedCity == 'semua' ||
      normalizedCity == 'seluruh lampung' ||
      normalizedCity == 'semua kota/kabupaten') {
    return true;
  }

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