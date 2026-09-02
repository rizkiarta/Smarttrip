import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../data/destinations_data.dart';
import '../services/api_service.dart';
import '../services/destination_service.dart';
import '../services/route_service.dart';
import '../widgets/smart_image.dart';
import 'itinerary_preview_screen.dart';
import '../theme/app_colors.dart';


// ================================================================
// AI ITINERARY SCREEN
// ================================================================
//
// Halaman ini menampilkan hasil rekomendasi rute & jadwal dari AI
// dalam bentuk timeline per hari (mirip mockup "Atur Rute & Jadwal").
//
// STATUS SAAT INI: data yang ditampilkan masih DUMMY, dibuat lewat
// _generateAIItinerary() di bawah. Struktur data & alur UI sudah
// dirancang final, jadi begitu backend/AI agent-nya siap, yang
// perlu diganti CUMA ISI fungsi _generateAIItinerary() — dari yang
// sekarang return data palsu, menjadi pemanggilan API AI beneran.
// Tidak ada bagian UI di bawah ini yang perlu diubah lagi.
//
// ================================================================

class AIItineraryScreen extends StatefulWidget {
  final Map<String, dynamic> travelData;

  // ============================================================
  // DESTINASI YANG SUDAH DIPILIH PENGGUNA PER HARI
  // ============================================================
  //
  // Dikirim dari DestinationSelectionScreen (tombol "Atur dengan AI").
  // Kalau diisi, AI HANYA menyusun urutan & jadwal dari destinasi
  // yang sudah dipilih user ini -- berdasarkan prediksi tingkat
  // kepadatan tiap destinasi -- bukan asal ambil dari pool
  // kategori+kota lagi.
  //
  // Kalau null/kosong (mis. layar ini dibuka langsung tanpa lewat
  // alur pemilihan destinasi, misalnya saat testing), fallback ke
  // pool lama (_buildDestinationPool) supaya layar tetap tidak
  // kosong/crash.
  //
  // ============================================================

  final Map<int, List<Map<String, dynamic>>>? destinationsByDay;

  // ============================================================
  // KOORDINAT LOKASI AWAL (UNTUK HITUNG JAM BERANGKAT & WAKTU
  // TEMPUH KE DESTINASI PERTAMA)
  // ============================================================
  //
  // Kalau null (mis. layar ini dibuka langsung tanpa lewat
  // TravelInformationScreen/DestinationSelectionScreen), fallback ke
  // titik tengah Bandar Lampung supaya perhitungan tetap jalan tanpa
  // crash.
  //
  // ============================================================

  final LatLng? startCoordinate;

  // ============================================================
  // NAMA ALAMAT LOKASI AWAL (HASIL REVERSE GEOCODING)
  // ============================================================
  //
  // Diteruskan apa adanya ke ItineraryPreviewScreen/
  // ItineraryDetailScreen (field 'startLocation') supaya tampilannya
  // konsisten dengan alur manual -- tanpa ini, preview akan selalu
  // menampilkan fallback teks "Lokasi awal".
  //
  // ============================================================

  final String? startLocationName;

  const AIItineraryScreen({
    super.key,
    required this.travelData,
    this.destinationsByDay,
    this.startCoordinate,
    this.startLocationName,
  });

  @override
  State<AIItineraryScreen> createState() => _AIItineraryScreenState();
}

class _AIItineraryScreenState extends State<AIItineraryScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;

  int selectedDay = 1;

  // Data itinerary per hari. Key = nomor hari, Value = list stop
  // (SUDAH dalam bentuk siap tampil: time, title, subtitle, dst).
  // Dihasilkan dari _rawDestinationsByDay lewat _buildStopsForDay --
  // jangan diubah manual di luar itu supaya jadwal tetap konsisten.
  Map<int, List<Map<String, dynamic>>> itineraryByDay = {};

  // ============================================================
  // DESTINASI MENTAH PER HARI (SUMBER PERHITUNGAN JADWAL)
  // ============================================================
  //
  // Berbeda dari itineraryByDay (yang sudah berupa stop siap tampil),
  // ini menyimpan data destinasi ASLI (id, kategori, koordinat, dst)
  // per hari, dengan urutan kunjungan yang sudah ditentukan. Setiap
  // kali ada perubahan (tambah destinasi, hapus destinasi, atau
  // generate ulang), yang diubah adalah list ini dulu, baru
  // itineraryByDay dihitung ulang dari sini lewat _buildStopsForDay
  // -- supaya jam berangkat, waktu tempuh, dan jam operasional selalu
  // konsisten dengan urutan destinasi yang sebenarnya.
  //
  // ============================================================

  Map<int, List<Map<String, dynamic>>> _rawDestinationsByDay = {};

  // Sumber acak untuk "Buat Ulang" -- baru dibuat ulang tiap kali
  // tombol ditekan, supaya urutan destinasi dengan jam padat yang
  // sama bisa berubah-ubah setiap generate ulang (bukan cuma diam di
  // urutan yang sama terus seperti sebelumnya).
  final math.Random _shuffleRandom = math.Random();

  // ============================================================
  // SEED "AI" UNTUK JAM STAY / KAPAN PULANG DARI TIAP DESTINASI
  // ============================================================
  //
  // Durasi kunjungan (jam stay) tiap destinasi sekarang ditentukan
  // "acak oleh AI" (lihat _randomVisitDurationHours), TAPI dibuat
  // deterministik dari hash(id destinasi + seed ini) -- BUKAN
  // math.Random langsung -- supaya durasi tidak ikut berubah setiap
  // kali _buildStopsForDay dipanggil ulang akibat aksi lain (hapus
  // satu destinasi, ubah urutan, dst). Seed ini HANYA dinaikkan saat
  // tombol "Buat Ulang" ditekan, sehingga hasil "acak"-nya baru
  // benar-benar berubah saat itu -- konsisten dengan pola yang sudah
  // dipakai _getCrowdPrediction/_orderByCrowdLevel di file ini.
  //
  // ============================================================

  int _regenerateSeed = 0;

  // Guard supaya rebuild jadwal satu hari (setelah hapus/reorder/
  // tambah destinasi) yang menunggu fetchRealRoute tidak menimpa
  // hasil dari rebuild yang lebih baru kalau pengguna sempat
  // melakukan aksi lain sebelum fetch sebelumnya selesai.
  final Map<int, int> _buildGenerationByDay = {};

  int get totalDays {
    final int? duration = widget.travelData['duration'] as int?;

    if (duration != null && duration > 0) {
      return duration;
    }

    // ------------------------------------------------------------
    // FALLBACK: HITUNG DARI destinationsByDay
    // ------------------------------------------------------------
    //
    // 'duration' TIDAK ikut disimpan ke SavedItineraryService (lihat
    // _handleNext), jadi kalau layar ini dibuka lewat "Edit
    // Itinerary" (plan_screen.dart -> _editItinerary), travelData
    // yang dikirim balik tidak punya 'duration' -- sebelum fallback
    // ini ada, totalDays selalu jatuh ke 1, sehingga itinerary
    // multi-hari terpotong jadi cuma Hari 1 setiap kali diedit.
    //
    // Dengan fallback ini, jumlah hari diambil dari hari terbesar
    // yang benar-benar ada isinya di destinationsByDay -- data yang
    // memang selalu dikirim lengkap saat edit.
    //
    // ------------------------------------------------------------

    if (widget.destinationsByDay != null &&
        widget.destinationsByDay!.isNotEmpty) {
      return widget.destinationsByDay!.keys.reduce(
        (a, b) => a > b ? a : b,
      );
    }

    return 1;
  }

  @override
  void initState() {
    super.initState();

    _loadItinerary();
  }

  // ============================================================
  // LOAD ITINERARY (PERTAMA KALI MASUK HALAMAN)
  // ============================================================

  Future<void> _loadItinerary() async {
    setState(() {
      isLoading = true;
    });

    // Generate pertama kali: urutan destinasi TIDAK diacak (hanya
    // diurutkan berdasarkan prediksi kepadatan), supaya tampilan awal
    // stabil/tidak berubah-ubah kalau layar sempat rebuild.
    final Map<int, List<Map<String, dynamic>>> result =
        await _generateDestinationsByDay(widget.travelData, randomize: false);

    if (!mounted) return;

    _rawDestinationsByDay = result;

    final Map<int, List<Map<String, dynamic>>> stops = await _buildAllDayStops();

    if (!mounted) return;

    setState(() {
      itineraryByDay = stops;
      isLoading = false;
    });
  }

  // ============================================================
  // GENERATE ULANG (TOMBOL "GENERATE" / "BUAT ULANG")
  // ============================================================
  //
  // Berbeda dari _loadItinerary: di sini urutan destinasi yang
  // jam padatnya sama diacak ulang (randomize: true), supaya tiap
  // kali tombol "Buat Ulang" ditekan, susunan rute berubah -- tetap
  // menghindari jam padat, tapi tidak selalu urutan yang sama persis.
  //
  // ============================================================

  Future<void> _regenerateItinerary() async {
    setState(() {
      isLoading = true;
      // Naikkan seed supaya jam stay/kapan pulang tiap destinasi ikut
      // "diacak ulang oleh AI", bukan cuma urutan destinasinya saja.
      _regenerateSeed++;
    });

    final Map<int, List<Map<String, dynamic>>> result =
        await _generateDestinationsByDay(widget.travelData, randomize: true);

    if (!mounted) return;

    _rawDestinationsByDay = result;

    final Map<int, List<Map<String, dynamic>>> stops = await _buildAllDayStops();

    if (!mounted) return;

    setState(() {
      itineraryByDay = stops;
      isLoading = false;
    });
  }

  // ============================================================
  // [DUMMY] GENERATE AI ITINERARY
  // ============================================================
  //
  // TODO(backend): ganti isi fungsi ini dengan pemanggilan API AI
  // agent, kirim `travelData` sebagai payload, lalu map hasilnya
  // ke struktur Map<int, List<Map<String,dynamic>>> yang sama
  // persis seperti di bawah ini:
  //
  // {
  //   1: [
  //     {
  //       'time': '04.50 - 05.20',
  //       'title': 'Berangkat',
  //       'subtitle': 'Dari Lokasi',
  //       'image': null,       // opsional, path asset/URL foto
  //       'icon': Icons.home,  // dipakai kalau image null
  //     },
  //     ...
  //   ],
  //   2: [...],
  // }
  //
  // Pool destinasi di bawah ini sudah disaring berdasarkan kategori
  // DAN kota/kabupaten tujuan yang dipilih di TravelInformationScreen
  // (lihat _buildDestinationPool). Kalau backend/AI agent sudah siap,
  // logika penyaringan ini bisa dipindah ke sisi server; struktur
  // hasil akhirnya tetap harus mengikuti format di atas.
  //
  // ============================================================

  // ============================================================
  // BANGUN POOL DESTINASI SESUAI KATEGORI + KOTA TUJUAN
  // ============================================================

  List<Map<String, String>> _buildDestinationPool(
    Map<String, dynamic> travelData,
  ) {
    final List<String> categories =
        (travelData['categories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final String? destinationCity = travelData['destination'] as String?;

    bool matchesCategory(Map<String, String> destination) {
      if (categories.isEmpty || categories.contains('Semua')) return true;
      return categories.contains(destination['category']);
    }

    bool matchesCity(Map<String, String> destination) {
      return destinationMatchesCity(
        destination['location']!,
        destinationCity,
      );
    }

    final liveModels = DestinationService.instance.destinations.value;
    final List<Map<String, String>> sourceData =
        liveModels.map((d) => d.toDisplayMap()).toList();

    List<Map<String, String>> pool = sourceData
        .where((destination) =>
            matchesCategory(destination) && matchesCity(destination))
        .toList();

    // ==========================================================
    // FALLBACK BERTAHAP
    // ==========================================================
    //
    // Kalau kombinasi kategori + kota tujuan tidak menghasilkan
    // destinasi sama sekali (misal kota tujuan belum punya
    // destinasi kategori tertentu), longgarkan filter secara
    // bertahap supaya itinerary tidak kosong.
    //
    // ==========================================================

    if (pool.isEmpty) {
      pool = sourceData.where(matchesCategory).toList();
    }

    if (pool.isEmpty) {
      pool = List<Map<String, String>>.from(sourceData);
    }

    return pool;
  }

  // ============================================================
  // ESTIMASI DURASI KUNJUNGAN PER KATEGORI
  // ============================================================

  // ============================================================
  // PREDIKSI KEPADATAN (DUMMY, DETERMINISTIK PER DESTINASI)
  // ============================================================
  //
  // TODO(backend): ganti dengan pemanggilan API prediksi kepadatan
  // sungguhan, mis. GET /crowd-prediction?destination_id=...&date=...
  // Formatnya sengaja disamakan dengan CrowdPredictionScreen ('Sepi'
  // / 'Sedang' / 'Ramai' + rentang jam padat) supaya nanti gampang
  // disatukan jadi satu sumber data bersama.
  //
  // Dibuat deterministik lewat hash id (bukan acak/random) supaya
  // prediksi untuk destinasi yang sama tetap konsisten selama sesi
  // ini -- tidak berubah-ubah setiap kali tombol "Buat Ulang" ditekan.
  //
  // ============================================================

  static const List<String> _crowdStatusCycle = ['Sepi', 'Sedang', 'Ramai'];

  static const List<List<int>> _peakHourSlots = [
    [8, 11],
    [9, 15],
    [10, 14],
    [13, 17],
    [7, 10],
    [11, 16],
  ];

  Map<String, dynamic> _getCrowdPrediction(String destinationKey) {
    final int hash = destinationKey.hashCode.abs();

    final String status = _crowdStatusCycle[hash % _crowdStatusCycle.length];
    final List<int> peak = _peakHourSlots[hash % _peakHourSlots.length];

    return {
      'status': status,
      'peakStart': peak[0],
      'peakEnd': peak[1],
    };
  }

  // ============================================================
  // JAM STAY / KAPAN PULANG DARI DESTINASI ("ACAK OLEH AI")
  // ============================================================
  //
  // TODO(backend): ganti dengan durasi kunjungan hasil rekomendasi AI
  // sungguhan (mis. dari histori kunjungan pengguna lain, jam padat
  // real-time, dst). Untuk sekarang, "AI" memilih titik acak di
  // dalam rentang jam wajar per kategori.
  //
  // Dibuat deterministik dari hash(id destinasi + _regenerateSeed) --
  // BUKAN math.Random langsung -- dengan alasan yang sama seperti
  // _getCrowdPrediction: supaya durasi destinasi lain TIDAK ikut
  // berubah setiap kali _buildStopsForDay dipanggil ulang akibat aksi
  // lain (hapus/reorder/tambah destinasi). Hasilnya baru benar-benar
  // "diacak ulang" saat tombol "Buat Ulang" ditekan (_regenerateSeed
  // naik).
  //
  // ============================================================

  static const Map<String, List<double>> _visitDurationRangeHours = {
    'Kuliner': [0.75, 1.5],
    'Budaya': [1.0, 2.0],
    'Buatan': [1.5, 2.5],
    'Alam': [1.5, 3.0],
  };

  double _randomVisitDurationHours(String destinationKey, String category) {
    final List<double> range =
        _visitDurationRangeHours[category] ?? _visitDurationRangeHours['Alam']!;

    final int hash = '$destinationKey#$_regenerateSeed'.hashCode.abs();

    final double fraction = (hash % 1000) / 1000.0;

    return range[0] + fraction * (range[1] - range[0]);
  }

  // ============================================================
  // BATASI JUMLAH DESTINASI PER HARI (SEKITAR 3-4)
  // ============================================================
  //
  // Berlaku untuk SEMUA jalur pembentukan itinerary AI: hasil dari
  // API AI Orchestrator, hasil fallback lokal dari destinasi yang
  // sudah dipilih user lewat "Atur dengan AI" (DestinationSelectionScreen),
  // maupun fallback pool kategori+kota kalau user belum memilih apa-
  // apa. Kalau destinasi yang tersedia untuk hari itu lebih dari
  // target, DIPOTONG ke target (destinasi kelebihan tidak dipakai --
  // urutan yang disisakan tetap ikut hasil _orderByCrowdLevel supaya
  // yang jam padatnya lebih pagi yang diprioritaskan). Kalau
  // destinasi yang tersedia justru LEBIH SEDIKIT dari target, dibiarkan
  // apa adanya -- fungsi ini tidak menambah-nambah destinasi baru
  // (itu tetap lewat tombol "Tambah Destinasi").
  //
  // Target (3 atau 4) dibuat deterministik dari hash(hari +
  // _regenerateSeed) -- konsisten selama sesi ini, tapi bisa berubah
  // (3<->4) tiap kali tombol "Buat Ulang" ditekan, sama seperti pola
  // acak lain di file ini.
  //
  // ============================================================

  static const int _minDestinationsPerDay = 3;
  static const int _maxDestinationsPerDay = 4;

  int _targetDestinationCountForDay(int day) {
    final int hash = 'day$day#$_regenerateSeed'.hashCode.abs();

    final int span = _maxDestinationsPerDay - _minDestinationsPerDay + 1;

    return _minDestinationsPerDay + (hash % span);
  }

  List<Map<String, dynamic>> _capDestinationsForDay(
    List<Map<String, dynamic>> destinations,
    int day,
  ) {
    final int target = _targetDestinationCountForDay(day);

    if (destinations.length <= target) return destinations;

    return destinations.take(target).toList();
  }

  // ============================================================
  // URUTKAN DESTINASI BERDASARKAN TINGKAT KEPADATAN
  // ============================================================
  //
  // Placeholder logika "scoring AI" yang nanti dipindah ke backend.
  // Aturan sekarang:
  //
  // 1. Destinasi yang jam padatnya lebih PAGI diurutkan lebih dulu,
  //    supaya sempat dikunjungi sebelum keburu ramai.
  // 2. Kalau jam padatnya kebetulan sama, destinasi dengan status
  //    lebih 'Ramai' didahulukan (dijadwalkan lebih longgar/pagi).
  //
  // Hasil urutan ini dipakai _generateAIItinerary untuk menyusun
  // jadwal -- termasuk menggeser jam kunjungan kalau slotnya ternyata
  // masih bentrok sama jam padat (lihat komentar di bawah).
  //
  // ============================================================

  List<Map<String, dynamic>> _orderByCrowdLevel(
    List<Map<String, dynamic>> destinationsForDay, {
    bool randomize = false,
  }) {
    const Map<String, int> statusRank = {'Sepi': 0, 'Sedang': 1, 'Ramai': 2};

    final List<Map<String, dynamic>> withCrowd = destinationsForDay.map((d) {
      final String key = (d['id'] as String?) ?? (d['name'] as String? ?? '');

      return {
        ...d,
        '_crowd': _getCrowdPrediction(key),
      };
    }).toList();

    // ==========================================================
    // KELOMPOKKAN BERDASARKAN JAM PADAT (peakStart)
    // ==========================================================
    //
    // Destinasi dengan jam padat lebih pagi tetap dikelompokkan lebih
    // dulu (supaya prinsip "hindari jam ramai" tetap terjaga), tapi
    // URUTAN DI DALAM satu kelompok yang sama bisa diacak kalau
    // `randomize` true (dipakai saat tombol "Buat Ulang" ditekan),
    // supaya hasilnya tidak selalu identik setiap generate ulang.
    //
    // ==========================================================

    final Map<int, List<Map<String, dynamic>>> buckets = {};

    for (final d in withCrowd) {
      final int peakStart = (d['_crowd'] as Map<String, dynamic>)['peakStart']
          as int;

      buckets.putIfAbsent(peakStart, () => []).add(d);
    }

    final List<int> sortedKeys = buckets.keys.toList()..sort();

    final List<Map<String, dynamic>> ordered = [];

    for (final key in sortedKeys) {
      final List<Map<String, dynamic>> bucket = buckets[key]!;

      if (randomize) {
        bucket.shuffle(_shuffleRandom);
      } else {
        bucket.sort((a, b) {
          final crowdA = a['_crowd'] as Map<String, dynamic>;
          final crowdB = b['_crowd'] as Map<String, dynamic>;

          return statusRank[crowdB['status']]!.compareTo(
            statusRank[crowdA['status']]!,
          );
        });
      }

      ordered.addAll(bucket);
    }

    return ordered;
  }

  // ============================================================
  // FALLBACK: AMBIL DARI POOL KATEGORI+KOTA (KALAU TIDAK ADA
  // DESTINASI YANG DIPILIH USER)
  // ============================================================
  //
  // Jumlah yang diambil sekarang mengikuti _targetDestinationCountForDay
  // (3 atau 4), BUKAN selalu 4 seperti sebelumnya. Pengambilan indeks
  // juga diubah dari modulo-berulang (yang bisa mengulang destinasi
  // YANG SAMA dua kali di hari yang sama kalau pool-nya lebih kecil
  // dari jumlah yang diminta) menjadi pengambilan unik: berhenti kalau
  // semua destinasi di pool sudah terpakai, bukan memutar ulang dari
  // awal.
  //
  // ============================================================

  List<Map<String, dynamic>> _fallbackPoolForDay(
    List<Map<String, String>> destinationPool,
    int day, {
    bool randomize = false,
  }) {
    if (destinationPool.isEmpty) return [];

    final int target = _targetDestinationCountForDay(day);
    final int count = math.min(target, destinationPool.length);

    final List<Map<String, dynamic>> picked = [];

    for (int i = 0; i < count; i++) {
      final destination = destinationPool[(i + day) % destinationPool.length];
      picked.add(Map<String, dynamic>.from(destination));
    }

    return _orderByCrowdLevel(picked, randomize: randomize);
  }

  bool isUsingFallbackMode = false;

  void _showFallbackDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBEB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFD97706),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.greyText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Lihat Jadwal Perjalanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TENTUKAN URUTAN DESTINASI PER HARI (LANGKAH 1: "AI" MEMILIH
  // & MENGURUTKAN, BELUM MENGHITUNG JAM)
  // ============================================================

  Future<Map<int, List<Map<String, dynamic>>>> _generateDestinationsByDay(
    Map<String, dynamic> travelData, {
    required bool randomize,
  }) async {
    // Attempt real API call to Laravel Gemini AI Orchestrator first
    if (ApiService.instance.isAuthenticated) {
      try {
        final List<String> categories = (travelData['categories'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];

        final List<String> destIds = [];
        if (widget.destinationsByDay != null) {
          widget.destinationsByDay!.values.forEach((dayList) {
            for (final d in dayList) {
              final String? id = (d['id'] as String?) ?? (d['destination_id'] as String?);
              if (id != null) destIds.add(id);
            }
          });
        }

        final body = {
          'destination_city': travelData['destination'] ?? '',
          'categories': categories,
          'duration_days': totalDays,
          'vehicle_type': travelData['vehicle'] ?? 'Mobil',
          'departure_time': '06:00',
          if (destIds.isNotEmpty) 'destination_ids': destIds,
        };

        final res = await ApiService.instance.post('ai/generate-itinerary', body: body);

        if (res != null && res['days'] is List) {
          final Map<int, List<Map<String, dynamic>>> apiResult = {};
          for (final dayItem in res['days']) {
            final int dayNum = dayItem['day_number'] ?? 1;
            final List<dynamic> items = dayItem['items'] ?? [];
            final List<Map<String, dynamic>> dayDests = [];

            for (final it in items) {
              final String destId = it['destination_id'] ?? '';
              final Map<String, String>? destData = findDestinationById(destId);
              if (destData != null) {
                dayDests.add({
                  ...destData,
                  'arrivalTime': it['arrival_time'],
                  'departureTime': it['departure_time'],
                });
              }
            }

            if (dayDests.isNotEmpty) {
              apiResult[dayNum] = _capDestinationsForDay(
                _orderByCrowdLevel(dayDests, randomize: randomize),
                dayNum,
              );
            }
          }

          if (apiResult.isNotEmpty) {
            if (mounted) {
              setState(() {
                isUsingFallbackMode = false;
              });
            }
            return apiResult;
          }
        }
      } catch (e) {
        debugPrint('AI Itinerary API error, falling back to local orchestrator: $e');
        if (mounted) {
          setState(() {
            isUsingFallbackMode = true;
          });

          String dialogTitle = 'Rencana Perjalanan Siap';
          String dialogMessage = 'Jadwal perjalanan Anda telah disusun dengan optimasi rute terbaik.';

          if (e is ApiException) {
            if (e.statusCode == 429) {
              dialogTitle = 'Penyusunan Jadwal Perjalanan';
              dialogMessage = 'Permintaan rekomendasi AI sedang berada dalam lalu lintas tinggi. Rencana perjalanan Anda tetap berhasil disusun secara optimal dengan rute efisien.';
            } else if (e.statusCode == 422) {
              dialogTitle = 'Pilihan Destinasi Disesuaikan';
              dialogMessage = 'Jadwal telah disusun menggunakan pilihan destinasi terbaik di wilayah tujuan Anda.';
            } else {
              dialogTitle = 'Rencana Perjalanan Siap';
              dialogMessage = 'Jadwal perjalanan Anda telah disesuaikan dengan urutan destinasi dan rute paling efisien.';
            }
          }

          _showFallbackDialog(dialogTitle, dialogMessage);
        }
      }
    }

    // Heuristic Fallback
    await Future.delayed(const Duration(milliseconds: 500));

    final List<Map<String, String>> destinationPool =
        _buildDestinationPool(travelData);

    final Map<int, List<Map<String, dynamic>>> generated = {};

    for (int day = 1; day <= totalDays; day++) {
      final List<Map<String, dynamic>>? selectedForDay =
          widget.destinationsByDay?[day];

      final List<Map<String, dynamic>> dayDestinations =
          (selectedForDay != null && selectedForDay.isNotEmpty)
              ? _capDestinationsForDay(
                  _orderByCrowdLevel(selectedForDay, randomize: randomize),
                  day,
                )
              : _fallbackPoolForDay(destinationPool, day, randomize: randomize);

      generated[day] = dayDestinations;
    }

    return generated;
  }


  // ============================================================
  // BANGUN STOP SIAP TAMPIL UNTUK SEMUA HARI DARI
  // _rawDestinationsByDay (LANGKAH 2: HITUNG JAM BERANGKAT,
  // WAKTU TEMPUH, & JAM OPERASIONAL)
  // ============================================================

  Future<Map<int, List<Map<String, dynamic>>>> _buildAllDayStops() async {
    final Map<int, List<Map<String, dynamic>>> result = {};

    for (final entry in _rawDestinationsByDay.entries) {
      result[entry.key] = await _buildStopsForDay(entry.key, entry.value);
    }

    return result;
  }

  // ============================================================
  // REBUILD JADWAL SATU HARI SAJA (SETELAH HAPUS/REORDER/TAMBAH
  // DESTINASI) -- ASYNC KARENA MENUNGGU fetchRealRoute, DIJAGA
  // DENGAN GENERATION TOKEN SUPAYA HASIL YANG SUDAH KETINGGALAN
  // TIDAK MENIMPA HASIL TERBARU (SAMA POLA DENGAN
  // ManualScheduleScreen._recalculateArrivalTimes).
  // ============================================================

  Future<void> _rebuildDayStops(
    int day,
    List<Map<String, dynamic>> destinations,
  ) async {
    final int myGeneration = (_buildGenerationByDay[day] ?? 0) + 1;
    _buildGenerationByDay[day] = myGeneration;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final List<Map<String, dynamic>> stops = await _buildStopsForDay(
      day,
      destinations,
    );

    if (_buildGenerationByDay[day] != myGeneration || !mounted) {
      return;
    }

    setState(() {
      itineraryByDay[day] = stops;
      isLoading = false;
    });
  }

  // Titik tengah Bandar Lampung, dipakai kalau startCoordinate asli
  // belum ada (layar dibuka tanpa lewat alur normal / testing).
  static const LatLng _fallbackStartCoordinate = LatLng(-5.4292, 105.2610);

  // ============================================================
  // BANGUN STOP SIAP TAMPIL UNTUK SATU HARI
  // ============================================================
  //
  // Alur baru (disamakan dengan ManualScheduleScreen):
  // 1. Jam berangkat MENGIKUTI input pengguna di TravelInformationScreen
  //    (lihat _departureTimeForDay) -- bukan dihitung mundur dari jam
  //    buka destinasi pertama lagi.
  // 2. Jam tiba tiap destinasi dihitung dari jarak/rute ASLI
  //    (fetchRealRoute, route_service.dart -- SAMA PERSIS dengan yang
  //    dipakai ManualScheduleScreen & RouteScreen), bukan estimasi
  //    garis lurus.
  // 3. Jam stay / kapan pulang dari tiap destinasi ditentukan "acak
  //    oleh AI" (lihat _randomVisitDurationHours) -- bukan durasi
  //    tetap per kategori lagi.
  // 4. Dari jam pulang itu, kalau masih ada destinasi berikutnya,
  //    jarak/rute dihitung lagi ke destinasi tersebut untuk menentukan
  //    jam sampainya -- persis pola loop di bawah ini.
  //
  // Jam buka/tutup & jam padat destinasi tetap dipertimbangkan supaya
  // kunjungan tidak jatuh pas tutup/ramai.
  //
  // ASYNC karena fetchRealRoute benar-benar fetch ke backend/OSRM
  // (bukan rumus lokal) -- lihat _rebuildDayStops untuk indikator
  // loading & _buildGenerationByDay untuk pengaman kalau dipanggil
  // ulang sebelum fetch sebelumnya selesai.
  //
  // ============================================================

  Future<List<Map<String, dynamic>>> _buildStopsForDay(
    int day,
    List<Map<String, dynamic>> destinations,
  ) async {
    if (destinations.isEmpty) return [];

    final String? vehicle = widget.travelData['vehicle'] as String?;

    final LatLng startCoordinate =
        widget.startCoordinate ?? _fallbackStartCoordinate;

    final List<Map<String, dynamic>> stops = [];

    // ==========================================================
    // DESTINASI PERTAMA: JAM BERANGKAT = INPUT PENGGUNA
    // ==========================================================

    final Map<String, dynamic> first = destinations.first;

    final LatLng? firstCoordinate = coordinateOfDestination(first);

    Duration travelToFirst;

    if (firstCoordinate != null) {
      final RouteResult route = await fetchRealRoute(
        startCoordinate,
        firstCoordinate,
        vehicle: vehicle,
      );

      travelToFirst = route.duration;
    } else {
      travelToFirst = const Duration(hours: 1);
    }

    final DateTime departureTime = _departureTimeForDay(day);

    // Waktu tiba di destinasi pertama = berangkat + waktu tempuh.
    final DateTime arrivalTime = departureTime.add(travelToFirst);

    stops.add({
      'time':
          '${_formatTime(departureTime)} - ${_formatTime(arrivalTime)}',
      'title': 'Berangkat',
      'subtitle':
          'Menuju ${first['name']} (~${_formatDuration(travelToFirst)})',
      'image': null,
      'icon': Icons.home_rounded,
      // Format "HH:MM" (titik dua), dipakai kalau nanti data ini
      // diteruskan ke ItineraryPreviewScreen/ItineraryDetailScreen
      // yang membaca field 'departureTime' dengan format itu (lihat
      // _handleNext).
      'departureTimeColon': _formatTimeColon(departureTime),
    });

    LatLng currentCoordinate = startCoordinate;
    DateTime currentClock = arrivalTime;

    // ==========================================================
    // LOOP SEMUA DESTINASI: JADWALKAN KUNJUNGAN SATU-SATU
    // ==========================================================

    for (int i = 0; i < destinations.length; i++) {
      final Map<String, dynamic> destination = destinations[i];

      final String category = (destination['category'] as String?) ?? 'Alam';

      final String destinationKey =
          (destination['id'] as String?) ?? (destination['name'] as String? ?? '');

      final double durationHours = _randomVisitDurationHours(
        destinationKey,
        category,
      );

      final OperatingHours hours = operatingHoursFor(destination);

      final LatLng? destCoordinate = coordinateOfDestination(destination);

      // Waktu tempuh dari titik sebelumnya ke destinasi ini (untuk
      // destinasi pertama sudah dihitung di atas sebagai travelToFirst,
      // untuk destinasi ke-2 dst dihitung dari destinasi sebelumnya --
      // dari rute ASLI, sama seperti alur manual).
      if (i > 0) {
        Duration travelHere;

        if (destCoordinate != null) {
          final RouteResult route = await fetchRealRoute(
            currentCoordinate,
            destCoordinate,
            vehicle: vehicle,
          );

          travelHere = route.duration;
        } else {
          travelHere = const Duration(minutes: 30);
        }

        currentClock = currentClock.add(travelHere);
      }

      // Kalau tiba lebih pagi dari jam buka, tunggu sampai buka.
      final DateTime openTime = _timeOfDay(hours.openHour, 0);

      if (currentClock.isBefore(openTime)) {
        currentClock = openTime;
      }

      final Map<String, dynamic>? crowd =
          destination['_crowd'] as Map<String, dynamic>?;

      // ======================================================
      // GESER JAM MULAI KALAU BENTROK JAM PADAT
      // ======================================================

      if (crowd != null) {
        final int peakStart = crowd['peakStart'] as int;
        final int peakEnd = crowd['peakEnd'] as int;

        final int currentHour = currentClock.hour;
        final double visitEndHour = currentHour + durationHours;

        final bool overlaps =
            currentHour < peakEnd && visitEndHour > peakStart;

        if (overlaps && peakEnd > currentHour) {
          final DateTime pastPeak = _timeOfDay(peakEnd, 0);

          if (pastPeak.isAfter(currentClock)) {
            currentClock = pastPeak;
          }
        }
      }

      // Jangan sampai jam kunjungan lewat jam tutup. PENTING: yang
      // dipotong adalah DURASI-nya, BUKAN jam mulai (visitStart) yang
      // dimundurkan -- visitStart di sini adalah jam TIBA sebenarnya
      // (sudah dihitung maju dari jam pulang destinasi sebelumnya +
      // waktu tempuh asli ke sini). Versi lama memutar mundur
      // currentClock ke "latestStart" supaya kunjungan "muat" sebelum
      // tutup -- itu justru menyebabkan jam kunjungan destinasi ini
      // bisa jatuh SEBELUM jam pulang destinasi sebelumnya, alias
      // tabrakan jadwal antar destinasi.
      final DateTime closeTime = _timeOfDay(hours.closeHour, 0);

      final DateTime visitStart = currentClock;

      // Destinasi sudah tutup PAS kita tiba (jadwal hari ini
      // kepadatan/jarak antar destinasi terlalu ketat) -- tetap
      // dicatat di jadwal dengan durasi simbolis 15 menit supaya
      // kelihatan jelas sebagai peringatan, bukan hilang diam-diam
      // atau malah "tabrakan" dengan destinasi sebelumnya.
      final bool alreadyClosedOnArrival = !visitStart.isBefore(closeTime);

      final DateTime visitEnd = alreadyClosedOnArrival
          ? visitStart.add(const Duration(minutes: 15))
          : _earlierOf(
              visitStart.add(Duration(minutes: (durationHours * 60).round())),
              closeTime,
            );

      stops.add({
        'time': '${_formatTime(visitStart)} - ${_formatTime(visitEnd)}',
        'title': destination['name'],
        // Ditampilkan dari durasi yang BENAR-BENAR dipakai untuk
        // menghitung visitEnd di atas (termasuk kalau durasinya
        // dipotong karena kepepet jam tutup) -- kalau destinasi
        // ternyata sudah tutup pas kita tiba, subtitle memberi tahu
        // itu secara eksplisit alih-alih diam-diam menampilkan jam
        // yang membingungkan.
        'subtitle': alreadyClosedOnArrival
            ? 'Tutup saat tiba -- jadwal terlalu padat, coba atur ulang urutan destinasi'
            : _formatDuration(visitEnd.difference(visitStart)),
        'image': destination['image'],
        'icon': null,
        'crowdStatus': crowd?['status'],
        // ------------------------------------------------------
        // FIELD TAMBAHAN UNTUK ItineraryPreviewScreen/
        // ItineraryDetailScreen (lihat _handleNext) -- tidak dipakai
        // oleh UI timeline di layar ini, aman ditambahkan.
        // ------------------------------------------------------
        'id': destination['id'],
        'category': category,
        'latitude': destination['latitude'],
        'longitude': destination['longitude'],
        'arrivalTimeColon': _formatTimeColon(visitStart),
        'departureTimeColon': _formatTimeColon(visitEnd),
      });

      currentClock = visitEnd;

      if (destCoordinate != null) {
        currentCoordinate = destCoordinate;
      }
    }

    return stops;
  }

  // ============================================================
  // HELPER WAKTU
  // ============================================================
  //
  // Dipakai tanggal dummy (2000-01-01) supaya bisa memakai
  // DateTime.add/subtract secara aman; hanya jam:menit yang benar-
  // benar dipakai/ditampilkan (lihat _formatTime).
  //
  // ============================================================

  DateTime _timeOfDay(int hour, int minute) {
    return DateTime(2000, 1, 1, hour, minute);
  }

  // Dipakai untuk memotong durasi kunjungan (bukan memundurkan jam
  // mulai) kalau kunjungan penuh tidak muat sebelum jam tutup.
  DateTime _earlierOf(DateTime a, DateTime b) {
    return a.isBefore(b) ? a : b;
  }

  // ============================================================
  // JAM BERANGKAT UNTUK SATU HARI (DARI INPUT PENGGUNA DI
  // TravelInformationScreen)
  // ============================================================
  //
  // Prioritas:
  // 1. widget.travelData['startTimesByDay'][day] -- jam berangkat per
  //    hari yang diisi user (TimeOfDay), format yang sama dipakai
  //    ManualScheduleScreen.
  // 2. widget.travelData['startTime'] -- fallback untuk Hari 1 kalau
  //    'startTimesByDay' tidak ada (kompatibel dengan payload lama).
  // 3. String "HH:mm"/"HH:MM" -- jaga-jaga kalau travelData datang
  //    dari alur "Edit Itinerary" yang menyimpan jam sebagai teks,
  //    bukan objek TimeOfDay.
  // 4. 06:00 -- fallback terakhir kalau semuanya tidak ada, supaya
  //    jadwal tetap bisa dihitung tanpa crash.
  //
  // ============================================================

  DateTime _departureTimeForDay(int day) {
    final dynamic startTimesByDayRaw = widget.travelData['startTimesByDay'];

    dynamic rawForDay;

    if (startTimesByDayRaw is Map) {
      rawForDay = startTimesByDayRaw[day];
    }

    rawForDay ??= (day == 1) ? widget.travelData['startTime'] : null;

    if (rawForDay is TimeOfDay) {
      return _timeOfDay(rawForDay.hour, rawForDay.minute);
    }

    if (rawForDay is String && rawForDay.contains(':')) {
      final List<String> parts = rawForDay.split(':');

      final int? hour = int.tryParse(parts[0]);
      final int? minute = parts.length > 1 ? int.tryParse(parts[1]) : null;

      if (hour != null && minute != null) {
        return _timeOfDay(hour, minute);
      }
    }

    return _timeOfDay(6, 0);
  }

  String _formatTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(time.hour)}.${two(time.minute)}';
  }

  // Format "HH:MM" (titik dua) -- dipakai khusus untuk data yang
  // diteruskan ke ItineraryPreviewScreen/ItineraryDetailScreen, yang
  // mem-parsing waktu dengan split(':') (lihat _calculateDuration di
  // itinerary_preview_screen.dart). Timeline di layar INI sendiri
  // tetap pakai _formatTime (titik) sesuai mockup aslinya.
  String _formatTimeColon(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(time.hour)}:${two(time.minute)}';
  }

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours jam $minutes menit';
    } else if (hours > 0) {
      return '$hours jam';
    }

    return '$minutes menit';
  }

  // ============================================================
  // HAPUS STOP DARI TIMELINE
  // ============================================================
  //
  // index 0 selalu "Berangkat" (bukan destinasi sungguhan, tidak ada
  // padanannya di _rawDestinationsByDay), jadi index destinasi = index
  // stop - 1. Setelah destinasi dihapus dari data mentah, jadwal hari
  // itu dihitung ulang dari awal (jam berangkat, waktu tempuh, dst
  // bisa berubah karena destinasi pertama/urutan berubah).
  //
  // ============================================================

  void _removeStop(int day, int index) {
    if (index == 0) return; // Stop "Berangkat" tidak bisa dihapus.

    final int destinationIndex = index - 1;

    final List<Map<String, dynamic>>? dayDestinations =
        _rawDestinationsByDay[day];

    if (dayDestinations == null ||
        destinationIndex < 0 ||
        destinationIndex >= dayDestinations.length) {
      return;
    }

    dayDestinations.removeAt(destinationIndex);

    // Jadwal dihitung ulang lewat fetchRealRoute (async), jadi tidak
    // lagi langsung di dalam setState -- lihat _rebuildDayStops untuk
    // indikator loading & pengaman generation token.
    unawaited(_rebuildDayStops(day, dayDestinations));
  }

  // ============================================================
  // UBAH URUTAN DESTINASI (DRAG & DROP MANUAL)
  // ============================================================
  //
  // oldIndex/newIndex di sini dalam skala DESTINASI (index 0 =
  // destinasi pertama), TIDAK termasuk stop "Berangkat" yang selalu
  // ditampilkan terpisah di atas dan tidak ikut proses geser (lihat
  // _buildTimeline). newIndex yang dikirim Flutter mengikuti konvensi
  // ReorderableListView/SliverReorderableList: kalau item digeser ke
  // BAWAH posisi asalnya, newIndex sudah dihitung SEOLAH item lama
  // sudah tidak ada di list, jadi harus dikurangi 1 dulu supaya insert
  // jatuh di posisi yang benar.
  //
  // Setelah urutan mentah diubah, jadwal hari itu dihitung ulang dari
  // awal lewat _buildStopsForDay supaya jam berangkat, waktu tempuh,
  // dan jam kunjungan tiap destinasi menyesuaikan urutan barunya.
  //
  // ============================================================

  void _reorderStop(int day, int oldIndex, int newIndex) {
    final List<Map<String, dynamic>> dayDestinations = List.from(
      _rawDestinationsByDay[day] ?? [],
    );

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex < 0 ||
        oldIndex >= dayDestinations.length ||
        newIndex < 0 ||
        newIndex >= dayDestinations.length) {
      return;
    }

    final Map<String, dynamic> moved = dayDestinations.removeAt(oldIndex);

    dayDestinations.insert(newIndex, moved);

    _rawDestinationsByDay[day] = dayDestinations;

    // Jadwal dihitung ulang lewat fetchRealRoute (async), jadi tidak
    // lagi langsung di dalam setState -- lihat _rebuildDayStops untuk
    // indikator loading & pengaman generation token.
    unawaited(_rebuildDayStops(day, dayDestinations));
  }

  // ============================================================
  // SELESAI -> KEMBALIKAN HASIL KE HALAMAN SEBELUMNYA
  // ============================================================

  // ============================================================
  // SELESAI -> MASUK KE PREVIEW (SAMA SEPERTI ALUR ATUR MANUAL)
  // ============================================================
  //
  // Sebelumnya fungsi ini cuma Navigator.pop dengan list flat, yang
  // ujung-ujungnya dibuang percuma (PlanScreen tidak lagi memakai
  // nilai balik push, lihat komentar di plan_screen.dart). Sekarang
  // disamakan dengan alur ManualScheduleScreen: data dibentuk jadi
  // "dailySchedules" (satu Map per hari, dengan key 'destinations'
  // berisi list destinasi + jam kunjungan), lalu di-push ke
  // ItineraryPreviewScreen -- layar itu sendiri yang nanti mengurus
  // simpan/lihat itinerary (lewat SavedItineraryService), jadi di
  // sini tidak perlu menunggu hasil apa pun untuk melanjutkan alur.
  //
  // ============================================================

  void _handleNext() {
    final List<Map<String, dynamic>> dailySchedules = [];

    for (int day = 1; day <= totalDays; day++) {
      final List<Map<String, dynamic>> stops = itineraryByDay[day] ?? [];

      if (stops.isEmpty) continue;

      // Stop pertama selalu "Berangkat" (lihat _buildStopsForDay),
      // sisanya destinasi sungguhan.
      final Map<String, dynamic> departureStop = stops.first;

      final List<Map<String, dynamic>> destinationStops = stops
          .skip(1)
          .map((stop) {
            return {
              'id': stop['id'],
              'name': stop['title'],
              'image': stop['image'],
              'category': stop['category'],
              'latitude': stop['latitude'],
              'longitude': stop['longitude'],
              'arrivalTime': stop['arrivalTimeColon'],
              'departureTime': stop['departureTimeColon'],
            };
          })
          .toList();

      dailySchedules.add({
        'day': day,
        // Dipertahankan kalau ini hasil "Edit Itinerary" (lihat
        // plan_screen.dart -> _editItinerary), supaya saat disimpan
        // lagi SavedItineraryService tahu ini UPDATE itinerary yang
        // sudah ada, bukan itinerary baru terpisah.
        'itineraryId': widget.travelData['itineraryId'],
        // 'source' dipakai PlanScreen (tombol "Edit Itinerary") untuk
        // tahu harus membuka lagi AIItineraryScreen ini, bukan
        // ManualScheduleScreen. Fallback 'ai' untuk jaga-jaga kalau
        // layar ini dibuka tanpa lewat DestinationSelectionScreen
        // (mis. _handleAIRecommendation lama / testing).
        'source': widget.travelData['source'] ?? 'ai',
        // FIX: sebelumnya 'duration' tidak ikut disimpan sama sekali,
        // jadi kalau itinerary ini dibuka lagi lewat "Edit Itinerary",
        // totalDays selalu jatuh ke fallback 1 dan hari ke-2 dst
        // hilang. Disimpan di sini supaya edit berikutnya tahu persis
        // itinerary ini berapa hari, tanpa perlu menghitung ulang
        // dari destinationsByDay.
        'duration': totalDays,
        'tripName': widget.travelData['tripName'],
        'startDate': widget.travelData['startDate'],
        'endDate': widget.travelData['endDate'],
        'participants': widget.travelData['participants'],
        'vehicle': widget.travelData['vehicle'],
        'destination': widget.travelData['destination'],
        'startLocation':
            (widget.startLocationName != null &&
                    widget.startLocationName!.trim().isNotEmpty)
                ? widget.startLocationName
                : 'Lokasi awal belum ditentukan',
        'startLatitude': widget.startCoordinate?.latitude,
        'startLongitude': widget.startCoordinate?.longitude,
        'departureTime': departureStop['departureTimeColon'],
        'destinations': destinationStops,
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ItineraryPreviewScreen(dailySchedules: dailySchedules);
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            const SizedBox(height: 16),

            _buildDayTabs(),

            const SizedBox(height: 8),

            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : _buildTimeline(context),
            ),

            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),

      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),

            child: Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),

              child: const Icon(
                Icons.chevron_left,
                color: AppColors.darkText,
                size: 26,
              ),
            ),
          ),

          const Expanded(
            child: Text(
              'Atur Rute & Jadwal',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ),

          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ============================================================
  // DAY TABS
  // ============================================================

  Widget _buildDayTabs() {
    return SizedBox(
      height: 42,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        padding: const EdgeInsets.symmetric(horizontal: 16),

        itemCount: totalDays,

        separatorBuilder: (context, index) => const SizedBox(width: 10),

        itemBuilder: (context, index) {
          final int day = index + 1;
          final bool isActive = day == selectedDay;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDay = day;
              });
            },

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22),

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBlue : const Color(0xFFF0F0F0),

                borderRadius: BorderRadius.circular(25),
              ),

              child: Text(
                'Hari $day',

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.greyText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          CircularProgressIndicator(color: AppColors.primaryBlue),

          SizedBox(height: 16),

          Text(
            'AI sedang menyusun rekomendasi rute...',

            style: TextStyle(fontSize: 14, color: AppColors.greyText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  Widget _buildTimeline(BuildContext context) {
    final List<Map<String, dynamic>> stops = itineraryByDay[selectedDay] ?? [];

    if (stops.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada rute untuk hari ini.',
          style: TextStyle(fontSize: 14, color: AppColors.greyText),
        ),
      );
    }

    // Stop pertama selalu "Berangkat" (lihat _buildStopsForDay) --
    // ditampilkan terpisah di atas, TIDAK ikut digeser urutannya.
    // Sisanya adalah destinasi sungguhan yang boleh disusun ulang
    // lewat drag & drop.
    final Map<String, dynamic> departureStop = stops.first;

    final List<Map<String, dynamic>> destinationStops = stops
        .skip(1)
        .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ========================================================
        // STOP "BERANGKAT" -- TETAP DI ATAS, TIDAK BISA DIGESER/DIHAPUS
        // ========================================================
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _buildTimelineItem(
              stop: departureStop,
              isFirst: true,
              isLast: destinationStops.isEmpty,
            ),
          ),
        ),

        // ========================================================
        // DESTINASI -- BISA DIGESER URUTANNYA (TAHAN IKON drag_indicator
        // DI SETIAP KARTU LALU SERET)
        // ========================================================
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverReorderableList(
            itemCount: destinationStops.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> stop = destinationStops[index];
              final bool isLast = index == destinationStops.length - 1;

              return _buildTimelineItem(
                key: ValueKey(
                  stop['id']?.toString() ?? '${stop['title']}_$index',
                ),
                stop: stop,
                isFirst: false,
                isLast: isLast,
                // index stop penuh = index destinasi + 1, karena stop
                // "Berangkat" menempati index 0 di _removeStop.
                onRemove: () => _removeStop(selectedDay, index + 1),
                dragHandle: ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              _reorderStop(selectedDay, oldIndex, newIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    Key? key,
    required Map<String, dynamic> stop,
    required bool isFirst,
    required bool isLast,
    VoidCallback? onRemove,
    Widget? dragHandle,
  }) {
    final String time = stop['time'] ?? '';
    final String title = stop['title'] ?? '';
    final String subtitle = stop['subtitle'] ?? '';
    final String? image = stop['image'] as String?;
    final IconData icon = (stop['icon'] as IconData?) ?? Icons.place_outlined;
    final String? crowdStatus = stop['crowdStatus'] as String?;

    return IntrinsicHeight(
      key: key,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // WAKTU + DOT + GARIS TIMELINE
          // ======================================================

          SizedBox(
            width: 78,

            child: Padding(
              padding: const EdgeInsets.only(top: 14),

              child: Text(
                time,

                style: const TextStyle(fontSize: 12, color: AppColors.greyText),
              ),
            ),
          ),

          Column(
            children: [
              // Garis di atas dot — nyambung ke item sebelumnya.
              // Item pertama tetap punya spasi yang sama (biar dot sejajar
              // dengan label waktu di sampingnya), tapi transparan karena
              // belum ada garis dari mana pun di atasnya.
              Container(
                width: 2,
                height: 14,
                color: isFirst
                    ? Colors.transparent
                    : AppColors.primaryBlue.withOpacity(0.6),
              ),

              Container(
                width: 16,
                height: 16,

                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryBlue, width: 3),
                ),
              ),

              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primaryBlue.withOpacity(0.6),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // ======================================================
          // CARD KONTEN
          // ======================================================

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),

              child: Container(
                padding: const EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(color: AppColors.borderColor),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    // ================================================
                    // FOTO / ICON
                    // ================================================

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),

                      child: image != null
                          ? SmartImage(
                              imagePathOrUrl: image,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 54,
                              height: 54,
                              color: AppColors.primaryBlue.withOpacity(0.12),
                              child: Icon(icon, color: AppColors.darkBlue, size: 26),
                            ),
                    ),

                    const SizedBox(width: 10),

                    // ================================================
                    // TEXT
                    // ================================================

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            title,

                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            subtitle,

                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.greyText,
                            ),
                          ),

                          if (crowdStatus != null) ...[
                            const SizedBox(height: 5),
                            _buildCrowdBadge(crowdStatus),
                          ],
                        ],
                      ),
                    ),

                    // ================================================
                    // DRAG HANDLE (KHUSUS DESTINASI YANG BISA DIGESER --
                    // STOP "BERANGKAT" TIDAK PUNYA INI)
                    // ================================================

                    if (dragHandle != null) ...[
                      const SizedBox(width: 4),
                      dragHandle,
                    ],

                    // ================================================
                    // TOMBOL HAPUS (STOP "BERANGKAT" TIDAK BISA DIHAPUS,
                    // JADI onRemove-NYA NULL DAN TOMBOL INI DISEMBUNYIKAN)
                    // ================================================

                    if (onRemove != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onRemove,

                        child: Container(
                          width: 26,
                          height: 26,

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderColor),
                          ),

                          child: const Icon(
                            Icons.close,
                            size: 15,
                            color: AppColors.greyText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGE TINGKAT KEPADATAN
  // ============================================================
  //
  // Warnanya disamakan dengan badge status di CrowdPredictionScreen
  // (Sepi = hijau, Sedang = kuning, Ramai = merah) supaya artinya
  // konsisten di seluruh aplikasi.
  //
  // ============================================================

  Widget _buildCrowdBadge(String status) {
    Color textColor;
    Color backgroundColor;

    switch (status) {
      case 'Sepi':
        textColor = Colors.green;
        backgroundColor = AppColors.successBg;
        break;

      case 'Sedang':
        textColor = const Color(0xFFE0A900);
        backgroundColor = const Color(0xFFFFF8DF);
        break;

      case 'Ramai':
      default:
        textColor = Colors.red;
        backgroundColor = AppColors.errorBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), // CHANGED - padding menyesuaikan font yang lebih besar

      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(Icons.circle, color: textColor, size: 6),

          const SizedBox(width: 4),

          Text(
            status,

            style: TextStyle(
              color: textColor,
              fontSize: 12, // CHANGED - font terkecil jadi 12
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTIONS (TAMBAHKAN / BUAT ULANG / GENERATE / SELANJUTNYA)
  // ============================================================

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

      decoration: BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Row(
            children: [
              // ==========================================
              // TAMBAHKAN (manual, tambah 1 stop kosong)
              // ==========================================

              Expanded(
                child: _buildSecondaryButton(
                  text: 'Tambahkan',
                  icon: Icons.add,
                  onTap: isLoading ? null : _handleAddStop,
                ),
              ),

              const SizedBox(width: 10),

              // ==========================================
              // GENERATE (regenerate AI)
              // ==========================================

              Expanded(
                child: _buildSecondaryButton(
                  text: 'Buat Ulang',
                  icon: Icons.refresh,
                  onTap: isLoading ? null : _regenerateItinerary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 46,

            child: ElevatedButton(
              onPressed: isLoading ? null : _handleNext,

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),

              child: const Text(
                'Selanjutnya',

                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 42,

      child: OutlinedButton.icon(
        onPressed: onTap,

        icon: Icon(icon, size: 17, color: AppColors.darkBlue),

        label: Text(
          text,

          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBlue,
          ),
        ),

        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryBlue),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(21),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAMBAH DESTINASI (BUKA PEMILIH DESTINASI)
  // ============================================================
  //
  // Menampilkan daftar destinasi (dari pool kategori+kota tujuan yang
  // sama seperti dipakai AI, lihat _buildDestinationPool) supaya user
  // bisa pilih sendiri destinasi tambahan untuk hari yang sedang
  // aktif. Destinasi yang sudah ada di hari itu disembunyikan dari
  // daftar supaya tidak dobel. Setelah dipilih, destinasi ditambahkan
  // ke _rawDestinationsByDay lalu jadwal hari itu dihitung ulang
  // (jam kunjungan destinasi lain BISA ikut bergeser kalau destinasi
  // baru ini disisipkan berdasarkan jam padatnya).
  //
  // ============================================================

  Future<void> _handleAddStop() async {
    final List<Map<String, String>> pool = _buildDestinationPool(
      widget.travelData,
    );

    final Set<String> existingIds = (_rawDestinationsByDay[selectedDay] ?? [])
        .map((d) => (d['id'] as String?) ?? (d['name'] as String? ?? ''))
        .toSet();

    final List<Map<String, String>> candidates = pool
        .where(
          (d) => !existingIds.contains(d['id'] ?? d['name'] ?? ''),
        )
        .toList();

    final Map<String, String>? picked = await showModalBottomSheet<
        Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DestinationPickerSheet(candidates: candidates),
    );

    if (picked == null) return;

    final List<Map<String, dynamic>> dayDestinations = List.from(
      _rawDestinationsByDay[selectedDay] ?? [],
    );

    dayDestinations.add(Map<String, dynamic>.from(picked));

    // Urutkan ulang berdasarkan prediksi kepadatan supaya destinasi
    // baru ini juga dijadwalkan menghindari jam ramai, bukan asal
    // ditaruh di akhir.
    final List<Map<String, dynamic>> reordered = _orderByCrowdLevel(
      dayDestinations,
    );

    _rawDestinationsByDay[selectedDay] = reordered;

    // Jadwal dihitung ulang lewat fetchRealRoute (async) -- fungsi ini
    // sudah async, jadi langsung di-await, sekalian menampilkan
    // indikator loading lewat _rebuildDayStops.
    await _rebuildDayStops(selectedDay, reordered);
  }
}

// ================================================================
// BOTTOM SHEET: PILIH DESTINASI TAMBAHAN
// ================================================================

class _DestinationPickerSheet extends StatefulWidget {
  final List<Map<String, String>> candidates;

  const _DestinationPickerSheet({required this.candidates});

  @override
  State<_DestinationPickerSheet> createState() =>
      _DestinationPickerSheetState();
}

class _DestinationPickerSheetState extends State<_DestinationPickerSheet> {
  final TextEditingController searchController = TextEditingController();
  String keyword = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get filtered {
    if (keyword.trim().isEmpty) return widget.candidates;

    final String query = keyword.trim().toLowerCase();

    return widget.candidates.where((d) {
      final String name = (d['name'] ?? '').toLowerCase();
      final String location = (d['location'] ?? '').toLowerCase();

      return name.contains(query) || location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> items = filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 14),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Pilih Destinasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => keyword = value),
                  decoration: InputDecoration(
                    hintText: 'Cari destinasi...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.greyText),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada destinasi lain yang bisa ditambahkan.',
                          style: TextStyle(fontSize: 14, color: AppColors.greyText),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final destination = items[index];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                destination['image'] ?? '',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.primaryBlue.withOpacity(0.12),
                                    child: const Icon(
                                      Icons.place_outlined,
                                      color: AppColors.primaryBlue,
                                    ),
                                  );
                                },
                              ),
                            ),
                            title: Text(
                              destination['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                              ),
                            ),
                            subtitle: Text(
                              '${destination['category'] ?? ''} • ${destination['location'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.greyText,
                              ),
                            ),
                            onTap: () => Navigator.pop(context, destination),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}