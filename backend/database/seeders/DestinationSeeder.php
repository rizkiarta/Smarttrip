<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Destination;
use App\Models\DestinationGalleryImage;
use Illuminate\Support\Facades\DB;

class DestinationSeeder extends Seeder
{
    public function run(): void
    {
        $destinations = $this->getDestinationsData();

        $count = 0;
        DB::beginTransaction();

        try {
            foreach ($destinations as $item) {
                if (empty($item['id']) || empty($item['name'])) {
                    continue;
                }

                // Clean reviews count: "120 ulasan" / "120 review" -> 120
                $reviewsCount = 0;
                if (!empty($item['reviews'])) {
                    preg_match('/\d+/', $item['reviews'], $rMatches);
                    $reviewsCount = isset($rMatches[0]) ? (int)$rMatches[0] : 0;
                }

                // Default hours & duration per category
                $category = $item['category'] ?? 'Alam';
                [$openHour, $closeHour, $duration] = match ($category) {
                    'Kuliner' => [8, 22, 1.0],
                    'Budaya'  => [8, 16, 1.5],
                    'Buatan'  => [9, 21, 2.0],
                    default   => [6, 18, 2.5],
                };

                Destination::updateOrCreate(
                    ['id' => $item['id']],
                    [
                        'name'                 => $item['name'],
                        'location'             => $item['location'] ?? 'Lampung',
                        'category'             => $category,
                        'description'          => $item['description'] ?? null,
                        'latitude'             => (float)($item['latitude'] ?? 0),
                        'longitude'            => (float)($item['longitude'] ?? 0),
                        'rating_avg'           => (float)($item['rating'] ?? 0),
                        'reviews_count'        => $reviewsCount,
                        'main_image'           => $item['image'] ?? null,
                        'price_range'          => $item['price'] ?? null,
                        'open_hour'            => $openHour,
                        'close_hour'           => $closeHour,
                        'visit_duration_hours' => $duration,
                    ]
                );

                $count++;
            }

            DB::commit();
            $this->command->info("Berhasil mengimpor {$count} destinasi ke database.");

        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Gagal mengimpor destinasi: " . $e->getMessage());
        }

        // Seed gallery images if present
        $this->seedGallery();
    }

    private function seedGallery(): void
    {
        $galleryData = [
            'pulau_wayang' => [
                'destinations/gallery/pulau_wayang.jpg',
                'destinations/gallery/pulau_wayang2.jpg',
                'destinations/gallery/pulau_wayang3.jpg',
                'destinations/gallery/pulau_wayang4.jpg',
            ],
        ];

        foreach ($galleryData as $destId => $images) {
            if (Destination::where('id', $destId)->exists()) {
                foreach ($images as $index => $img) {
                    DestinationGalleryImage::updateOrCreate(
                        ['destination_id' => $destId, 'image_url' => $img],
                        ['sort_order' => $index + 1]
                    );
                }
            }
        }
    }

    /**
     * Pure PHP Data array for all destinations (Standalone, Server-Ready)
     */
    private function getDestinationsData(): array
    {
        return [
            // 1. Pesawaran
            [
                'id' => 'pulau_pahawang',
                'name' => 'Pulau Pahawang',
                'location' => 'Pesawaran',
                'category' => 'Alam',
                'rating' => '4.8',
                'reviews' => '340 ulasan',
                'image' => 'assets/images/pulau_pahawang.jpg',
                'description' => 'Surga snorkeling terkenal di Lampung dengan terumbu karang indah, ikan nemo, dan keindahan pulau pasir timbul.',
                'price' => 'Rp 150.000 - Rp 300.000',
                'latitude' => '-5.6705',
                'longitude' => '105.2241',
            ],
            [
                'id' => 'pulau_tegal_mas',
                'name' => 'Pulau Tegal Mas',
                'location' => 'Pesawaran',
                'category' => 'Alam',
                'rating' => '4.7',
                'reviews' => '280 ulasan',
                'image' => 'assets/images/pulau_tegal_mas.jpg',
                'description' => 'Destinasi wisata pulau bergaya Maldives di Lampung dengan penginapan terapung dan spot snorkeling penyu.',
                'price' => 'Rp 50.000 - Rp 150.000',
                'latitude' => '-5.5841',
                'longitude' => '105.2562',
            ],
            [
                'id' => 'pantai_sari_ringgung',
                'name' => 'Pantai Sari Ringgung',
                'location' => 'Pesawaran',
                'category' => 'Alam',
                'rating' => '4.5',
                'reviews' => '210 ulasan',
                'image' => 'assets/images/pantai_sari_ringgung.jpg',
                'description' => 'Pantai keluarga populer dengan fenomena Pasir Timbul dan Masjid Terapung di tengah laut.',
                'price' => 'Rp 20.000',
                'latitude' => '-5.5562',
                'longitude' => '105.2341',
            ],
            [
                'id' => 'pantai_mutun',
                'name' => 'Pantai Mutun',
                'location' => 'Pesawaran',
                'category' => 'Alam',
                'rating' => '4.4',
                'reviews' => '195 ulasan',
                'image' => 'assets/images/pantai_mutun.jpg',
                'description' => 'Pantai pasir putih terdekat dari kota Bandar Lampung, tempat ideal untuk rekreasi air dan menyeberang ke Pulau Tangkil.',
                'price' => 'Rp 25.000',
                'latitude' => '-5.5181',
                'longitude' => '105.2536',
            ],
            [
                'id' => 'pantai_klara',
                'name' => 'Pantai Klara',
                'location' => 'Pesawaran',
                'category' => 'Alam',
                'rating' => '4.6',
                'reviews' => '180 ulasan',
                'image' => 'assets/images/pantai_klara.jpg',
                'description' => 'Singkatan Kelapa Rapat, pantai bernuansa rindang dengan ombak sangat tenang dan jajaran pohon kelapa.',
                'price' => 'Rp 15.000',
                'latitude' => '-5.5789',
                'longitude' => '105.2154',
            ],
            [
                'id' => 'pulau_wayang',
                'name' => 'Pulau Wayang',
                'location' => 'Pesawaran',
                'category' => 'Alam',
                'rating' => '4.9',
                'reviews' => '150 ulasan',
                'image' => 'assets/images/pulau_wayang.jpg',
                'description' => 'Gugusan tebing batu menjulang tinggi mirip Raja Ampat di ujung selatan Pesawaran.',
                'price' => 'Rp 350.000',
                'latitude' => '-5.7335',
                'longitude' => '105.2012',
            ],
            [
                'id' => 'teluk_hantu',
                'name' => 'Teluk Hantu',
                'location' => 'Pesawaran',
                'category' => 'Alam',
                'rating' => '4.7',
                'reviews' => '95 ulasan',
                'image' => 'assets/images/teluk_hantu.jpg',
                'description' => 'Teluk tersembunyi dengan air laut jernih kehijauan dan pantai pasir putih yang belum terjamah di Punduh Pedada.',
                'price' => 'Rp 10.000',
                'latitude' => '-5.6811',
                'longitude' => '105.2285',
            ],
            [
                'id' => 'seafood_pesawaran',
                'name' => 'RM Bahari Cempaka Mutun',
                'location' => 'Pesawaran',
                'category' => 'Kuliner',
                'rating' => '4.6',
                'reviews' => '110 ulasan',
                'image' => 'assets/images/seafood_pesawaran.jpg',
                'description' => 'Restoran seafood tepi pantai yang menyajikan cumi bakar, kerapu asam manis, dan kelapa muda segar.',
                'price' => 'Rp 40.000 - Rp 120.000',
                'latitude' => '-5.5191',
                'longitude' => '105.2541',
            ],

            // 2. Bandar Lampung
            [
                'id' => 'museum_lampung',
                'name' => 'Museum Lampung',
                'location' => 'Bandar Lampung',
                'category' => 'Budaya',
                'rating' => '4.5',
                'reviews' => '160 ulasan',
                'image' => 'assets/images/museum_lampung.jpg',
                'description' => 'Museum negeri tempat koleksi artefak budaya, kerajinan kain tapis, dan sejarah provinsi Lampung.',
                'price' => 'Rp 5.000',
                'latitude' => '-5.3721',
                'longitude' => '105.2425',
            ],
            [
                'id' => 'puncak_mas',
                'name' => 'Puncak Mas',
                'location' => 'Bandar Lampung',
                'category' => 'Buatan',
                'rating' => '4.6',
                'reviews' => '240 ulasan',
                'image' => 'assets/images/puncak_mas.jpg',
                'description' => 'Taman wisata perbukitan di Sukadanaham dengan rumah pohon, sepeda gantung, dan pemandangan laut & kota.',
                'price' => 'Rp 20.000',
                'latitude' => '-5.4128',
                'longitude' => '105.2274',
            ],
            [
                'id' => 'bukit_sakura_kemiling',
                'name' => 'Bukit Sakura Kemiling',
                'location' => 'Bandar Lampung',
                'category' => 'Buatan',
                'rating' => '4.4',
                'reviews' => '130 ulasan',
                'image' => 'assets/images/bukit_sakura_kemiling.jpg',
                'description' => 'Destinasi wisata keluarga bertema taman Jepang lengkap dengan persewaan baju kimono dan ornamen bunga sakura.',
                'price' => 'Rp 15.000',
                'latitude' => '-5.3995',
                'longitude' => '105.2281',
            ],
            [
                'id' => 'lembah_hijau',
                'name' => 'Lembah Hijau',
                'location' => 'Bandar Lampung',
                'category' => 'Buatan',
                'rating' => '4.5',
                'reviews' => '310 ulasan',
                'image' => 'assets/images/lembah_hijau.jpg',
                'description' => 'Taman rekreasi keluarga terpadu yang memadukan waterboom, taman satwa, outbond, dan penginapan.',
                'price' => 'Rp 25.000 - Rp 50.000',
                'latitude' => '-5.4215',
                'longitude' => '105.2341',
            ],
            [
                'id' => 'trans_studio_mini_lampung',
                'name' => 'Trans Studio Mini Lampung',
                'location' => 'Bandar Lampung',
                'category' => 'Buatan',
                'rating' => '4.6',
                'reviews' => '270 ulasan',
                'image' => 'assets/images/trans_studio_mini_lampung.jpg',
                'description' => 'Taman bermain indoor modern dengan berbagai wahana permainan seru untuk anak-anak hingga dewasa di Transmart.',
                'price' => 'Rp 50.000 - Rp 200.000',
                'latitude' => '-5.3855',
                'longitude' => '105.2751',
            ],
            [
                'id' => 'mie_khodon',
                'name' => 'Mie Khodon',
                'location' => 'Bandar Lampung',
                'category' => 'Kuliner',
                'rating' => '4.7',
                'reviews' => '450 ulasan',
                'image' => 'assets/images/mie_khodon.jpg',
                'description' => 'Kuliner legendaris mie goreng & mie rebus khas Lampung bertekstur tebal sejak 1960 di Teluk Betung.',
                'price' => 'Rp 20.000 - Rp 35.000',
                'latitude' => '-5.4418',
                'longitude' => '105.2635',
            ],
            [
                'id' => 'seruit_khas_lampung',
                'name' => 'RM Seruit Mendanau',
                'location' => 'Bandar Lampung',
                'category' => 'Kuliner',
                'rating' => '4.8',
                'reviews' => '380 ulasan',
                'image' => 'assets/images/seruit_khas_lampung.jpg',
                'description' => 'Restoran khas masakan tradisional Lampung dengan hidangan utama Seruit (ikan bakar/rebus, sambal terasi & tempoyak).',
                'price' => 'Rp 30.000 - Rp 75.000',
                'latitude' => '-5.4182',
                'longitude' => '105.2561',
            ],
            [
                'id' => 'cafe_2',
                'name' => 'Cafe Rumah Kayu',
                'location' => 'Bandar Lampung',
                'category' => 'Kuliner',
                'rating' => '4.7',
                'reviews' => '520 ulasan',
                'image' => 'assets/images/cafe_rumah_kayu.jpg',
                'description' => 'Restoran keluarga dengan saung-saung di atas kolam, interior nuansa kayu asri, dan sajian seafood komplit.',
                'price' => 'Rp 50.000 - Rp 150.000',
                'latitude' => '-5.3855',
                'longitude' => '105.2751',
            ],

            // 3. Lampung Selatan
            [
                'id' => 'anak_krakatau',
                'name' => 'Anak Krakatau',
                'location' => 'Lampung Selatan',
                'category' => 'Alam',
                'rating' => '4.9',
                'reviews' => '410 ulasan',
                'image' => 'assets/images/anak_krakatau.jpg',
                'description' => 'Gunung berapi aktif legendaris di Selat Sunda dengan pesona eksotis medan vulkanik dan keanekaragaman bahari.',
                'price' => 'Rp 500.000 - Rp 1.500.000',
                'latitude' => '-6.1022',
                'longitude' => '105.4231',
            ],
            [
                'id' => 'siger',
                'name' => 'Menara Siger',
                'location' => 'Lampung Selatan',
                'category' => 'Budaya',
                'rating' => '4.6',
                'reviews' => '530 ulasan',
                'image' => 'assets/images/siger.png',
                'description' => 'Ikon kebanggaan Lampung berbentuk mahkota Siger emas di atas bukit Bakauheni, titik nol gerbang pulau Sumatra.',
                'price' => 'Rp 10.000',
                'latitude' => '-5.8715',
                'longitude' => '105.7554',
            ],
            [
                'id' => 'pantai_kyokko',
                'name' => 'Pantai Kyokko',
                'location' => 'Lampung Selatan',
                'category' => 'Alam',
                'rating' => '4.5',
                'reviews' => '120 ulasan',
                'image' => 'assets/images/pantai_kyokko.jpg',
                'description' => 'Pantai indah dengan latar belakang pemandangan Gunung Rajabasa dan hamparan pasir halus di Rajabasa Kalianda.',
                'price' => 'Rp 15.000',
                'latitude' => '-5.6881',
                'longitude' => '105.5786',
            ],

            // 4. Tanggamus
            [
                'id' => 'pantai_gigi_hiu',
                'name' => 'Pantai Gigi Hiu',
                'location' => 'Tanggamus',
                'category' => 'Alam',
                'rating' => '4.8',
                'reviews' => '290 ulasan',
                'image' => 'assets/images/pantai_gigi_hiu.jpg',
                'description' => 'Pantai fenomena batu karang tajam menjulang menyerupai gigi hiu di Kelumbayan, favorit fotografer dunia.',
                'price' => 'Rp 15.000',
                'latitude' => '-5.7541',
                'longitude' => '105.0562',
            ],
            [
                'id' => 'teluk_kiluan',
                'name' => 'Teluk Kiluan',
                'location' => 'Tanggamus',
                'category' => 'Alam',
                'rating' => '4.8',
                'reviews' => '360 ulasan',
                'image' => 'assets/images/teluk_kiluan.jpg',
                'description' => 'Destinasi laut populer untuk melihat atraksi lumba-lumba bebas di samudra dan laguna laut Kolam Laguna.',
                'price' => 'Rp 250.000',
                'latitude' => '-5.7725',
                'longitude' => '105.1051',
            ],
            [
                'id' => 'air_terjun_way_lalaan',
                'name' => 'Air Terjun Way Lalaan',
                'location' => 'Tanggamus',
                'category' => 'Alam',
                'rating' => '4.5',
                'reviews' => '170 ulasan',
                'image' => 'assets/images/way_lalaan.jpg',
                'description' => 'Air terjun bertingkat di kaki Gunung Tanggamus yang sudah dikenal sejak zaman kolonial Belanda.',
                'price' => 'Rp 10.000',
                'latitude' => '-5.4741',
                'longitude' => '104.6285',
            ],

            // 5. Lampung Barat & Pesisir Barat
            [
                'id' => 'danau_ranau',
                'name' => 'Danau Ranau',
                'location' => 'Lampung Barat',
                'category' => 'Alam',
                'rating' => '4.8',
                'reviews' => '310 ulasan',
                'image' => 'assets/images/danau_ranau.jpg',
                'description' => 'Danau vulkanik terbesar kedua di Sumatra dengan latar Gunung Seminung yang sejuk dan pemandian air panas.',
                'price' => 'Rp 10.000',
                'latitude' => '-4.8794',
                'longitude' => '103.9313',
            ],
            [
                'id' => 'pantai_labuhan_jukung',
                'name' => 'Pantai Labuhan Jukung',
                'location' => 'Pesisir Barat',
                'category' => 'Alam',
                'rating' => '4.7',
                'reviews' => '280 ulasan',
                'image' => 'assets/images/pantai_labuhan_jukung.jpg',
                'description' => 'Pantai ikonik ibu kota Krui dengan pemandangan sunset memukau, ombak selancar, dan spot kuliner malam.',
                'price' => 'Rp 5.000',
                'latitude' => '-5.1915',
                'longitude' => '103.9281',
            ],
            [
                'id' => 'pantai_tanjung_setia',
                'name' => 'Pantai Tanjung Setia',
                'location' => 'Pesisir Barat',
                'category' => 'Alam',
                'rating' => '4.9',
                'reviews' => '390 ulasan',
                'image' => 'assets/images/pantai_tanjung_setia.jpg',
                'description' => 'Surga selancar dunia di Pesisir Barat tempat kompetisi WSL Krui Pro dengan ombak kelas internasional.',
                'price' => 'Rp 10.000',
                'latitude' => '-5.3112',
                'longitude' => '103.9025',
            ],
            [
                'id' => 'pulau_pisang',
                'name' => 'Pulau Pisang',
                'location' => 'Pesisir Barat',
                'category' => 'Alam',
                'rating' => '4.8',
                'reviews' => '160 ulasan',
                'image' => 'assets/images/pulau_pisang.jpg',
                'description' => 'Pulau kecil eksotis lepas pantai Krui dengan rumah panggung tua bersejarah, lumba-lumba, dan pasir putih.',
                'price' => 'Rp 30.000',
                'latitude' => '-5.1125',
                'longitude' => '103.8412',
            ],

            // 6. Metro & Pringsewu & Lampung Timur
            [
                'id' => 'taman_merdeka_metro',
                'name' => 'Taman Merdeka Metro',
                'location' => 'Metro',
                'category' => 'Buatan',
                'rating' => '4.6',
                'reviews' => '310 ulasan',
                'image' => 'assets/images/taman_merdeka_metro.jpg',
                'description' => 'Alun-alun pusat Kota Metro dengan tugu menara air kuno Belanda, area bermain, dan pusat kuliner malam.',
                'price' => 'Gratis',
                'latitude' => '-5.1138',
                'longitude' => '105.3068',
            ],
            [
                'id' => 'tugu_bambu_pringsewu',
                'name' => 'Tugu Bambu Pringsewu',
                'location' => 'Pringsewu',
                'category' => 'Buatan',
                'rating' => '4.5',
                'reviews' => '180 ulasan',
                'image' => 'assets/images/tugu_bambu_pringsewu.jpg',
                'description' => 'Landmark gerbang utama Pringsewu bertema replika rerimbunan bambu bertingkat.',
                'price' => 'Gratis',
                'latitude' => '-5.3591',
                'longitude' => '104.9734',
            ],
            [
                'id' => 'taman_nasional_way_kambas',
                'name' => 'Taman Nasional Way Kambas',
                'location' => 'Lampung Timur',
                'category' => 'Alam',
                'rating' => '4.8',
                'reviews' => '480 ulasan',
                'image' => 'assets/images/way_kambas.jpg',
                'description' => 'Pusat konservasi gajah Sumatra legendaris dan suaka rhino (badak) terbesar di Indonesia.',
                'price' => 'Rp 20.000 - Rp 50.000',
                'latitude' => '-5.0542',
                'longitude' => '105.7481',
            ],

            // 7. Tulang Bawang Barat & Way Kanan
            [
                'id' => 'masjid_agung_tubaba',
                'name' => 'Masjid Agung Tulang Bawang Barat',
                'location' => 'Tulang Bawang Barat',
                'category' => 'Budaya',
                'rating' => '4.9',
                'reviews' => '450 ulasan',
                'image' => 'assets/images/masjid_agung_tubaba.jpg',
                'description' => 'Masjid 99 Cahaya bertema arsitektur kontemporer tanpa kubah tradisional di Kompleks Dunia Islam Tubaba.',
                'price' => 'Gratis',
                'latitude' => '-4.4539',
                'longitude' => '105.0601',
            ],
            [
                'id' => 'air_terjun_way_kanan',
                'name' => 'Air Terjun Curup Gangsa',
                'location' => 'Way Kanan',
                'category' => 'Alam',
                'rating' => '4.8',
                'reviews' => '210 ulasan',
                'image' => 'assets/images/air_terjun_way_kanan.jpg',
                'description' => 'Air terjun megah menyerupai Niagara mini di Kasui Way Kanan dengan tebing batu lebar bergemuruh.',
                'price' => 'Rp 10.000',
                'latitude' => '-4.6281',
                'longitude' => '104.3812',
            ],
        ];
    }
}
