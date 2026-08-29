import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../data/destinations_data.dart';
import '../services/saved_itinerary_service.dart';
import '../services/destination_service.dart';
import '../widgets/smart_image.dart';
import '../services/api_service.dart';
import '../services/auth_guard.dart';

import 'travel_information_screen.dart';
import 'route_screen.dart';

// ================================================================
// TRIP SCREEN
// ================================================================
//
// Tab "Trip" di bottom navbar. Berbeda dari PlanScreen (daftar
// RENCANA yang belum/akan dijalankan), layar ini nunjukkin
// itinerary yang SEDANG berjalan -- yaitu itinerary tersimpan yang
// tanggal hari ini ada di antara startDate & endDate-nya.
//
// Deteksinya OTOMATIS lewat _findActiveTrip() setiap
// SavedItineraryService berubah (ValueListenableBuilder), TANPA
// perlu tombol/aksi manual apa pun dari user -- begitu tanggal
// sistem sudah masuk hari-H, itinerary itu otomatis pindah "muncul"
// di sini walau kartunya masih ada juga di PlanScreen.
//
// STATUS SAAT INI (sesuai arahan): baru TAMPILAN. Bagian yang masih
// dummy/placeholder ditandai jelas di komentar masing-masing --
// "Progres Hari Ini", "Aktivitas Berikutnya", tombol "Rute", dan
// panel "Penyesuaian Itinerary" -- logic aslinya menyusul bertahap.
//
// ================================================================

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  // ============================================================
  // COLORS — belum ada padanannya di AppColors, tetap lokal
  // ============================================================

  static const Color warnBg = Color(0xFFFDECEC);
  static const Color warnText = Color(0xFFD7373F);

  // ============================================================
  // MAP
  // ============================================================

  final MapController _mapController = MapController();

  // Lampung Barat -- sama seperti default ItineraryDetailScreen.
  static const LatLng defaultCenter = LatLng(-5.0415, 104.0695);

  // ============================================================
  // PENYESUAIAN ITINERARY (UI-ONLY UNTUK SEKARANG)
  // ============================================================
  //
  // Index opsi yang lagi dipilih di panel bawah. Default 0 ("Ubah
  // urutan destinasi") supaya tampilan awal cocok sama mockup yang
  // sudah nunjukkin opsi pertama terpilih (border biru).
  //
  // TODO(fungsi bertahap): "Terapkan Perubahan" belum ngapa-ngapain
  // beneran -- lihat _applyAdjustment().
  //
  // ============================================================

  int _selectedAdjustment = 0;

  // ============================================================
  // PROGRES DARI RouteScreen (sinkron via callback)
  // ============================================================
  //
  // Jumlah stop yang sudah "Ditandai Sudah Sampai" di RouteScreen,
  // diisi lewat onStopIndexChanged waktu user pop kembali ke sini --
  // lihat _buildNextActivityCard. State biasa (bukan disimpan
  // permanen ke SavedItineraryService), jadi reset kalau app
  // ditutup -- sesuai keputusan yang diambil. Dipakai buat gerakin
  // _buildProgressCard dan gaya "off" di _buildDestinationRow.
  //
  // ============================================================

  int _completedStopIndex = 0;

  // ============================================================
  // HARI YANG SEDANG DILIHAT (day switcher, gaya ItineraryDetailScreen)
  // ============================================================
  //
  // null berarti belum dipilih manual -- default ke hari ini
  // (_dayNumberToday) begitu trip aktif ketemu, lihat
  // _buildActiveTrip. Begitu user pindah tab hari lewat
  // _buildDayTabs, nilainya disetel manual dan progress
  // (_completedStopIndex) direset karena destinasi yang ditampilkan
  // ganti hari.
  //
  // ============================================================

  @override
  void initState() {
    super.initState();
    if (ApiService.instance.isAuthenticated) {
      SavedItineraryService.instance.fetchItineraries();
    }
  }

  int? _selectedDayNumber;
  int _selectedActiveTripIndex = 0;

  void _selectDay(int day) {
    if (day == _selectedDayNumber) return;
    setState(() {
      _selectedDayNumber = day;
      _completedStopIndex = 0;
    });
  }

  // ============================================================
  // OPSI PENYESUAIAN ITINERARY (tergantung jumlah hari trip)
  // ============================================================
  //
  // Trip 1 hari: cuma 3 opsi dasar (ubah urutan, ubah destinasi,
  // batalkan kunjungan destinasi) -- "Pindah ke hari lain" gak
  // relevan karena gak ada hari lain buat dipindah. Trip >1 hari:
  // opsi "Pindah ke hari lain" ditambahkan di akhir. Lihat
  // _buildAdjustmentPanel & panel ini cuma ditampilkan kalau ada
  // destinasi yang kedeteksi ramai (lihat crowded di
  // _buildActiveTrip) -- kalau gak ada, fitur ini off/disembunyikan.
  //
  // ============================================================

  List<Map<String, String>> _adjustmentOptionsFor(int totalDays) {
    final List<Map<String, String>> options = [
      {
        'title': 'Ubah urutan destinasi',
        'subtitle': 'Mengatur ulang rencana destinasi ke jam kunjungan yang lebih sepi',
      },
      {
        'title': 'Ubah destinasi',
        'subtitle': 'Mengganti destinasi lain yang lebih sepi',
      },
      {
        'title': 'Batalkan kunjungan destinasi',
        'subtitle': 'Menghapus destinasi ini dari rencana kunjungan hari ini',
      },
    ];

    if (totalDays > 1) {
      options.add({
        'title': 'Pindah ke hari lain',
        'subtitle': 'Memindahkan kunjungan ke hari berikutnya',
      });
    }

    return options;
  }

  // ============================================================
  // CARI ITINERARY YANG SEDANG BERJALAN (HARI-H)
  // ============================================================
  //
  // TODO(fungsi bertahap): kalau ada lebih dari satu itinerary yang
  // tanggalnya overlap di hari yang sama, baru diambil yang PERTAMA
  // ketemu di list. Belum ada penanganan khusus buat kasus itu.
  //
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  List<List<Map<String, dynamic>>> _findAllActiveTrips(
    List<List<Map<String, dynamic>>> itineraries,
  ) {
    if (itineraries.isEmpty) return [];

    final DateTime today = _dateOnly(DateTime.now());
    final List<List<Map<String, dynamic>>> activeTrips = [];

    for (final itinerary in itineraries) {
      if (itinerary.isEmpty) continue;

      final DateTime? start = _parseDate(itinerary.first['startDate']);
      final DateTime? end = _parseDate(itinerary.first['endDate']);

      if (start != null && end != null) {
        final DateTime startDay = _dateOnly(start);
        final DateTime endDay = _dateOnly(end);

        if (!today.isBefore(startDay) && !today.isAfter(endDay)) {
          activeTrips.add(itinerary);
        }
      }
    }

    if (activeTrips.isNotEmpty) return activeTrips;

    return itineraries;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  // Hari ke berapa (1-based) dari itinerary ini HARI INI.
  int _dayNumberToday(List<Map<String, dynamic>> itinerary) {
    final DateTime? start = _parseDate(itinerary.first['startDate']);

    if (start == null) return 1;

    final int diff =
        _dateOnly(DateTime.now()).difference(_dateOnly(start)).inDays;

    if (diff < 0) return 1;
    final int duration = _totalDaysOf(itinerary);
    if (diff >= duration) return duration;

    return diff + 1;
  }


  // Total hari itinerary ini. Pakai field 'duration' kalau ada
  // (baru mulai ikut tersimpan -- lihat ai_itinerary_screen.dart),
  // fallback ke jumlah hari yang benar-benar ada datanya.
  int _totalDaysOf(List<Map<String, dynamic>> itinerary) {
    final dynamic duration = itinerary.first['duration'];

    if (duration is int && duration > 0) return duration;

    return itinerary.length;
  }

  Map<String, dynamic> _scheduleForDay(
    List<Map<String, dynamic>> itinerary,
    int dayNumber,
  ) {
    for (final schedule in itinerary) {
      final dynamic day = schedule['day'];

      final int? parsed =
          day is int ? day : int.tryParse(day?.toString() ?? '');

      if (parsed == dayNumber) return schedule;
    }

    // Fallback: kalau hari ke-N gak ketemu (mis. data kosong di
    // tengah), tampilkan hari terakhir yang ada supaya layar tidak
    // kosong total.
    return itinerary.last;
  }

  // ============================================================
  // VALUE HELPERS (sama seperti ItineraryDetailScreen)
  // ============================================================

  String _value(Map<String, dynamic> data, String key, {String fallback = ''}) {
    final value = data[key];
    if (value == null) return fallback;
    return value.toString();
  }

  String _destinationName(Map<String, dynamic> destination) {
    return _value(destination, 'name', fallback: 'Destinasi');
  }

  String _destinationImage(Map<String, dynamic> destination) {
    for (final key in ['image', 'main_image', 'mainImage', 'photo', 'cover_image', 'image_url']) {
      final val = destination[key]?.toString().trim();
      if (val != null && val.isNotEmpty && val != 'null') {
        return val;
      }
    }
    final destId = destination['id']?.toString() ?? '';
    final destName = destination['name']?.toString() ?? '';
    final liveDest = findDestinationById(destId) ?? findDestinationByName(destName);
    if (liveDest != null && liveDest['image'] != null && liveDest['image']!.isNotEmpty) {
      return liveDest['image']!;
    }
    return '';
  }

  String _arrivalTime(Map<String, dynamic> destination) {
    return _value(destination, 'arrivalTime', fallback: '--:--');
  }

  String _departureTime(Map<String, dynamic> destination) {
    return _value(destination, 'departureTime', fallback: '--:--');
  }

  List<Map<String, dynamic>> _getDestinations(Map<String, dynamic> schedule) {
    final raw = schedule['destinations'];
    final List<Map<String, dynamic>> result = [];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return result;
  }

  String _calculateDuration(String arrival, String departure) {
    try {
      if (arrival == '--:--' || departure == '--:--') return '';

      final arrivalParts = arrival.split(':');
      final departureParts = departure.split(':');

      if (arrivalParts.length != 2 || departureParts.length != 2) return '';

      final int arrivalTotal =
          int.parse(arrivalParts[0]) * 60 + int.parse(arrivalParts[1]);

      int departureTotal =
          int.parse(departureParts[0]) * 60 + int.parse(departureParts[1]);

      if (departureTotal < arrivalTotal) departureTotal += 24 * 60;

      final int difference = departureTotal - arrivalTotal;
      final int hours = difference ~/ 60;
      final int minutes = difference % 60;

      if (hours > 0 && minutes > 0) return '$hours jam $minutes menit';
      if (hours > 0) return '$hours jam';
      return '$minutes menit';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // CROWD STATUS (dummy deterministik, sama pola dengan
  // ItineraryDetailScreen -- otomatis pakai data asli begitu
  // backend prediksi kepadatan tersambung)
  // ============================================================

  String _getCrowdStatus(Map<String, dynamic> destination, int index) {
    final value = destination['crowdStatus'] ??
        destination['crowdLevel'] ??
        destination['crowd'] ??
        destination['kepadatan'] ??
        destination['statusKepadatan'];

    if (value != null) {
      final status = value.toString().trim().toLowerCase();
      if (status.contains('ramai')) return 'Ramai';
      if (status.contains('sedang') ||
          status.contains('medium') ||
          status.contains('moderate')) {
        return 'Sedang';
      }
      return 'Sepi';
    }

    final String destId = (destination['id'] as String?) ?? (destination['destination_id'] as String? ?? '');
    final String name = _destinationName(destination).toLowerCase();
    final predictions = DestinationService.instance.crowdPredictions.value;

    for (final p in predictions) {
      if ((destId.isNotEmpty && p.destinationId == destId) || p.name.toLowerCase() == name) {
        return p.status;
      }
    }

    return 'Sepi';
  }


  Color _crowdColor(String status) {
    switch (status) {
      case 'Ramai':
        return const Color(0xFFE53935);
      case 'Sedang':
        return const Color(0xFFD9A900);
      default:
        return const Color(0xFF20A447);
    }
  }

  // ============================================================
  // CROWD HEATMAP DOTS (DI PETA PREVIEW)
  // ============================================================
  //
  // Sama persis gaya & logikanya dengan
  // ItineraryDetailScreen._buildCrowdHeatmapDots -- gumpalan titik
  // warna-warni di sekitar pin destinasi (merah = Ramai, kuning =
  // Sedang, hijau = Sepi), posisinya di-generate pakai Random(seed)
  // supaya stabil (bukan acak tiap rebuild).
  // ============================================================

  Widget _buildCrowdHeatmapDots(String status, int seed) {
    final Color color = _crowdColor(status);

    final int dotCount = switch (status) {
      'Ramai' => 22,
      'Sedang' => 15,
      _ => 10,
    };

    final math.Random random = math.Random(seed);

    const double size = 92;
    const double center = size / 2;

    final List<Widget> dots = List.generate(dotCount, (i) {
      final double radius = math.sqrt(random.nextDouble()) * (size / 2 - 6);
      final double angle = random.nextDouble() * 2 * math.pi;
      final double dx = center + radius * math.cos(angle);
      final double dy = center + radius * math.sin(angle);
      final double dotSize = 4 + random.nextDouble() * 5;
      final double opacity = 0.25 + random.nextDouble() * 0.35;

      return Positioned(
        left: dx - dotSize / 2,
        top: dy - dotSize / 2,
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        ),
      );
    });

    return IgnorePointer(
      child: SizedBox(width: size, height: size, child: Stack(children: dots)),
    );
  }

  Widget _buildCrowdLabel(String status) {
    final Color color = _crowdColor(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // Destinasi pertama di jadwal hari ini yang statusnya "Ramai",
  // dipakai buat banner peringatan di bawah timeline. null kalau
  // tidak ada satu pun yang ramai.
  Map<String, dynamic>? _firstCrowdedDestination(
    List<Map<String, dynamic>> destinations,
  ) {
    for (int i = 0; i < destinations.length; i++) {
      if (_getCrowdStatus(destinations[i], i) == 'Ramai') {
        return destinations[i];
      }
    }
    return null;
  }

  // ============================================================
  // MAP HELPERS
  // ============================================================

  double? _readDouble(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // Titik lokasi keberangkatan -- SAMA PERSIS logikanya dengan
  // ItineraryDetailScreen._getStartPoint, supaya "Lokasi Awal" yang
  // ditampilkan di preview map dua layar ini tidak beda sumber data.
  // Prioritas: startLatitude/startLongitude asli dari data trip,
  // fallback ke titik dummy di wilayah kabupaten/kota tujuan.
  LatLng? _getStartPoint(Map<String, dynamic> schedule) {
    final lat = _readDouble(schedule, 'startLatitude');
    final lng = _readDouble(schedule, 'startLongitude');

    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }

    final district = _value(
      schedule,
      'destination',
      fallback: _value(schedule, 'district', fallback: 'Kabupaten Lampung Barat'),
    );

    return coordinateForRegency(district, seed: schedule['tripName'] ?? district);
  }

  List<LatLng> _mapPoints(List<Map<String, dynamic>> destinations) {
    final List<LatLng> points = [];

    for (final destination in destinations) {
      final LatLng? coordinate = coordinateOfDestination(destination);
      if (coordinate != null) points.add(coordinate);
    }

    return points;
  }

  // ============================================================
  // MAP MARKERS
  // ============================================================
  //
  // Gaya pin SEKARANG disamakan dengan ItineraryDetailScreen: ikon
  // lokasi + badge nomor urut kecil di pojok kanan-atas (bukan lagi
  // cuma ikon polos yang membesar untuk destinasi pertama).
  // Bedanya, di sini warnanya TETAP mengikuti progres kunjungan hari
  // ini (completedIndex) supaya info "sudah dikunjungi / sedang
  // dituju / belum dituju" yang sudah ada sebelumnya tidak hilang --
  // abu-abu+centang untuk yang sudah dikunjungi, biru gelap besar
  // untuk yang sedang dituju, biru muda untuk yang belum.
  //
  // ============================================================

  List<Marker> _buildMarkers(
    List<Map<String, dynamic>> destinations,
    int completedIndex,
  ) {
    final List<Marker> markers = [];

    for (int i = 0; i < destinations.length; i++) {
      final LatLng? coordinate = coordinateOfDestination(destinations[i]);
      if (coordinate == null) continue;

      final bool passed = i < completedIndex;
      final bool active = i == completedIndex;

      final Color pinColor = passed ? AppColors.doneGrey : (active ? AppColors.darkBlue : AppColors.paleBlue);

      // Heatmap kepadatan -- ditambahkan SEBELUM pin nomornya (biar
      // ada di lapisan bawah), sama seperti di ItineraryDetailScreen.
      final String crowdStatus = _getCrowdStatus(destinations[i], i);
      final int dotSeed =
          _destinationName(destinations[i]).codeUnits.fold<int>(0, (sum, code) => sum + code) + i;

      markers.add(
        Marker(
          point: coordinate,
          width: 92,
          height: 92,
          child: _buildCrowdHeatmapDots(crowdStatus, dotSeed),
        ),
      );

      markers.add(
        Marker(
          point: coordinate,
          width: 48,
          height: 60,
          child: Column(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: pinColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        passed ? Icons.check_rounded : Icons.location_on,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 20, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar
                        height: 20, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: pinColor, width: 1.4),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: pinColor,
                            fontSize: 12, // CHANGED - font terkecil jadi 12
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 3, height: 12, color: pinColor),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  // Marker titik keberangkatan -- SAMA PERSIS gayanya dengan
  // ItineraryDetailScreen (ikon rumah, hijau) supaya langsung
  // kelihatan mana titik "berangkat", bukan destinasi ke-1.
  Marker? _buildStartMarker(Map<String, dynamic> schedule) {
    final startPoint = _getStartPoint(schedule);
    if (startPoint == null) return null;

    return Marker(
      point: startPoint,
      width: 48,
      height: 60,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
          ),
          Container(width: 3, height: 12, color: AppColors.successGreen),
        ],
      ),
    );
  }

  void _fitMapToPoints(List<LatLng> points) {
    if (points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (points.length == 1) {
        _mapController.move(points.first, 14);
        return;
      }

      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!ApiService.instance.isAuthenticated) {
      return _buildGuestState(context);
    }
    return ValueListenableBuilder<List<List<Map<String, dynamic>>>>(
      valueListenable: SavedItineraryService.instance.itineraries,
      builder: (context, itineraries, _) {
        final List<List<Map<String, dynamic>>> activeTrips =
            _findAllActiveTrips(itineraries);

        if (activeTrips.isEmpty) {
          return _buildEmptyState(context);
        }

        final int safeIndex =
            _selectedActiveTripIndex.clamp(0, activeTrips.length - 1);
        final List<Map<String, dynamic>> activeTrip = activeTrips[safeIndex];

        return Scaffold(
          backgroundColor: Colors.white,
          body: _buildActiveTrip(
            context,
            activeTrip,
            activeTrips: activeTrips,
            currentIndex: safeIndex,
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE (Image 1)
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    // Shell (header foto biru + judul/subjudul + sudut rounded 42)
    // disamakan PERSIS dengan PlanScreen._buildScaffold, sesuai
    // permintaan -- sebelumnya layar ini polos putih tanpa header
    // sama sekali. Isi di dalamnya (icon, judul, deskripsi, tombol)
    // tetap konten aslinya trip screen, cuma dibungkus shell yang
    // sama.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ======================================================
          // BLUE HEADER (sama persis dengan PlanScreen)
          // ======================================================

          Container(
            height: 285,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_header.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ==================================================
                // HEADER TEXT
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Pantau perjalananmu yang sedang berlangsung',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // WHITE CONTENT (rounded 42, sama dengan PlanScreen)
                // ==================================================

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(42),
                        topRight: Radius.circular(42),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        children: [
                          const Spacer(flex: 5),

                          // Ukuran disamakan PERSIS dengan
                          // PlanScreen._buildEmptyState: SizedBox
                          // 100x100 berisi Image.asset 55x55.
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset(
                              'assets/images/smarttrip_logo_icon.png',
                              width: 55,
                              height: 55,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.travel_explore_rounded,
                                  size: 60,
                                  color: AppColors.primaryBlue.withValues(alpha: 0.85),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'Hari ini belum ada trip',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Yuk buat itinerary untuk merencanakan perjalananmu berikutnya',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.greyText, height: 1.4),
                          ),

                          const SizedBox(height: 26),

                          SizedBox(
                            width: 180,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TravelInformationScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Buat Itinerary',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const Spacer(flex: 7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(height: 285, width: double.infinity, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/background_header.png'), fit: BoxFit.cover))),
          SafeArea(
            child: Column(
              children: [
                Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(25, 30, 25, 0), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Trip', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)), SizedBox(height: 5), Text('Pantau perjalananmu yang sedang berlangsung', style: TextStyle(color: Colors.white, fontSize: 12))])),
                const SizedBox(height: 35),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(42), topRight: Radius.circular(42))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        children: [
                          const Spacer(flex: 5),
                          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_outline, color: AppColors.primaryBlue, size: 36)),
                          const SizedBox(height: 18),
                          const Text('Masuk untuk melihat trip', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          const SizedBox(height: 8),
                          const Text('Trip aktifmu akan muncul di sini saat tanggal perjalanan tiba.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.4)),
                          const SizedBox(height: 20),
                          SizedBox(width: 180, height: 44, child: ElevatedButton(onPressed: () => showLoginRequiredSheet(context, action: 'melihat trip'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Masuk / Daftar', style: TextStyle(fontWeight: FontWeight.w600)))),
                          const Spacer(flex: 7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE TRIP STATE (Image 2)
  // ============================================================

  Widget _buildActiveTrip(
    BuildContext context,
    List<Map<String, dynamic>> itinerary, {
    List<List<Map<String, dynamic>>> activeTrips = const [],
    int currentIndex = 0,
  }) {
    final int totalDays = _totalDaysOf(itinerary);

    // Default ke hari ini (sesuai tanggal sistem) kalau user belum
    // pernah pindah tab hari secara manual -- lihat _selectDay &
    // _buildDayTabs. Di-clamp supaya tetap dalam rentang totalDays
    // (jaga-jaga kalau hari ini di luar rentang trip).
    final int todayDayNumber = _dayNumberToday(itinerary).clamp(1, totalDays);
    final int dayNumber = (_selectedDayNumber ?? todayDayNumber).clamp(1, totalDays);

    final Map<String, dynamic> schedule = _scheduleForDay(itinerary, dayNumber);
    final List<Map<String, dynamic>> destinations = _getDestinations(schedule);

    final List<LatLng> points = _mapPoints(destinations);
    final LatLng? startPoint = _getStartPoint(schedule);
    _fitMapToPoints(startPoint != null ? [startPoint, ...points] : points);

    // ============================================================
    // STATUS SELESAI HARI YANG SEDANG DITAMPILKAN (PERSISTED)
    // ============================================================
    //
    // Beda dengan _completedStopIndex (state UI biasa, reset kalau
    // ganti tab hari / app ditutup), 'dayCompleted' ini DISIMPAN lewat
    // SavedItineraryService.markDayCompleted -- jadi begitu sebuah
    // hari sudah dikonfirmasi selesai (lihat _buildFinishDayCard /
    // _markDayFinished), badge & progress hari itu tetap kebaca
    // "Selesai" walau user pindah-pindah tab hari atau buka-tutup app.
    //
    // Dipakai sebagai OVERRIDE: kalau hari yang ditampilkan memang
    // sudah completed, anggap semua destinasinya sudah dikunjungi
    // (effectiveCompletedIndex = total) terlepas dari nilai
    // _completedStopIndex saat ini.
    //
    // ============================================================

    final String? itineraryId = SavedItineraryService.instance.itineraryIdOf(itinerary);
    final bool dayCompletedPersisted = itineraryId != null &&
        SavedItineraryService.instance.isDayCompleted(itinerary, dayNumber);

    final int effectiveCompletedIndex = dayCompletedPersisted
        ? destinations.length
        : _completedStopIndex.clamp(0, destinations.length);

    // Aktivitas berikutnya sekarang ikut effectiveCompletedIndex --
    // begitu destinasi 1 ditandai "Sudah Sampai" di RouteScreen,
    // kartu ini otomatis lanjut nunjukkin destinasi 2, dst. null
    // kalau semua destinasi hari ini sudah dikunjungi (kartu
    // "Aktivitas Berikutnya" jadi disembunyikan, lihat
    // _buildMapWithOverlay) ATAU hari ini memang sudah completed
    // (dayCompletedPersisted).
    final Map<String, dynamic>? nextActivity =
        effectiveCompletedIndex < destinations.length
            ? destinations[effectiveCompletedIndex]
            : null;

    final Map<String, dynamic>? crowded = _firstCrowdedDestination(destinations);

    // Kendaraan yang SUDAH DIISI user untuk trip ini (dari
    // TravelInformationScreen) -- dialirkan ke tombol "Rute" supaya
    // mode kendaraan yang aktif di RouteScreen otomatis sesuai data
    // ini, bukan selalu default "Mobil". Lihat _buildNextActivityCard
    // dan RouteScreen.initialVehicle.
    final String vehicle = _value(schedule, 'vehicle', fallback: 'Mobil');

    // ============================================================
    // SEMUA DESTINASI HARI YANG SEDANG DITAMPILKAN SUDAH DIKUNJUNGI?
    // ============================================================
    //
    // Begitu nextActivity == null (semua destinasi hari ini sudah
    // "Ditandai Sudah Sampai"), kartu "Aktivitas Berikutnya" + tombol
    // Rute otomatis hilang dari overlay peta (lihat _buildMapWithOverlay,
    // cuma dirender kalau nextActivity != null) -- jadi user kelihatan
    // "mentok" tanpa aksi lanjutan. _buildFinishDayCard di bawah ngisi
    // kekosongan itu -- SEKARANG bisa muncul di HARI MANA PUN (bukan
    // cuma hari terakhir seperti dulu), karena statusnya per-hari,
    // bukan per-trip. Begitu dikonfirmasi lewat _markDayFinished, kartu
    // ini otomatis hilang lagi (diganti badge "Selesai") karena
    // dayCompletedPersisted sudah true, jadi tidak nawarin dikonfirmasi
    // dua kali.
    //
    // ============================================================

    final bool allDestinationsDoneToday =
        destinations.isNotEmpty && nextActivity == null;
    final bool showFinishDayCard = !dayCompletedPersisted;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildMapWithOverlay(
            schedule,
            destinations,
            nextActivity,
            vehicle,
            effectiveCompletedIndex,
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(42),
                topRight: Radius.circular(42),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeTrips.length > 1)
                        _buildTripSwitcher(context, activeTrips, currentIndex),

                      _buildTripInfo(
                        schedule,
                        dayNumber,
                        totalDays,
                        isDayCompleted: dayCompletedPersisted,
                      ),

                      const SizedBox(height: 18),

                      _buildProgressCard(destinations, effectiveCompletedIndex),

                      if (showFinishDayCard) ...[
                        const SizedBox(height: 16),
                        _buildFinishDayCard(
                          itinerary,
                          dayNumber,
                          isLastDay: dayNumber == totalDays,
                          allDone: allDestinationsDoneToday,
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDayTimeline(schedule, destinations, effectiveCompletedIndex),
                ),

                if (crowded != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCrowdWarning(crowded),
                  ),

                  // Panel "Penyesuaian Itinerary" cuma relevan kalau
                  // ADA destinasi yang kedeteksi bakal ramai saat
                  // kunjungan -- makanya dibungkus kondisi yang sama
                  // dengan _buildCrowdWarning di atas. Gak ada
                  // destinasi ramai = fitur ini off (disembunyikan),
                  // bukan cuma disabled.
                  const SizedBox(height: 26),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAdjustmentPanel(totalDays),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAP + KARTU "AKTIVITAS BERIKUTNYA" (OVERLAY)
  // ============================================================

  Widget _buildMapWithOverlay(
    Map<String, dynamic> schedule,
    List<Map<String, dynamic>> destinations,
    Map<String, dynamic>? nextActivity,
    String vehicle,
    int completedIndex,
  ) {
    final LatLng? startPoint = _getStartPoint(schedule);
    final List<LatLng> destinationPoints = _mapPoints(destinations);

    // Titik keberangkatan dimasukkan LEBIH DULU, sebelum destinasi,
    // supaya garis rute-nya menggambarkan "dari mana berangkat -> ke
    // mana saja tujuannya" -- SAMA PERSIS pola yang dipakai
    // ItineraryDetailScreen (_buildRoutePoints/_getMapPoints), supaya
    // bentuk garisnya konsisten antar dua layar.
    final List<LatLng> routePoints = [
      if (startPoint != null) startPoint,
      ...destinationPoints,
    ];

    final Marker? startMarker = _buildStartMarker(schedule);

    return SizedBox(
      height: 330,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: defaultCenter,
              initialZoom: 13,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smarttrip',
              ),

              // Garis rute putus-putus -- gaya (warna, ketebalan,
              // pola dash) disamakan persis dengan peta preview
              // ItineraryDetailScreen (_buildMap), supaya "gambaran
              // rute" di kedua layar ini benar-benar sama bentuknya.
              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4,
                      color: AppColors.darkBlue,
                      // Tanpa 'const' -- StrokePattern.dashed tidak
                      // bisa dievaluasi di constant expression (lihat
                      // catatan yang sama di ItineraryDetailScreen).
                      pattern: StrokePattern.dashed(segments: [14, 10]),
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  if (startMarker != null) startMarker,
                  ..._buildMarkers(destinations, completedIndex),
                ],
              ),
            ],
          ),

          if (nextActivity != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildNextActivityCard(nextActivity, destinations, vehicle),
            ),
        ],
      ),
    );
  }

  Widget _buildNextActivityCard(
    Map<String, dynamic> destination,
    List<Map<String, dynamic>> allDestinations,
    String vehicle,
  ) {
    final String time = _arrivalTime(destination);
    final String name = _destinationName(destination);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktivitas Berikutnya',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$time  $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Sekarang mengirim SEMUA destinasi hari ini sebagai
              // rute multi-stop (bukan cuma satu tujuan lagi) --
              // RouteScreen yang menghitung leg lokasi user -> stop
              // 1 -> stop 2 -> dst, dan menggambar tiap leg beda
              // gaya (on/off/sudah dilewati) sesuai progress.
              //
              // Destinasi yang koordinatnya tidak ketemu (null)
              // DILEWATI dari daftar stop -- bukan bikin seluruh
              // tombol gagal -- supaya satu data yang bolong tidak
              // menggagalkan seluruh rute hari itu.
              ElevatedButton(
                onPressed: () {
                  final List<RouteStop> stops = [];

                  for (int i = 0; i < allDestinations.length; i++) {
                    final item = allDestinations[i];
                    final LatLng? coordinate = coordinateOfDestination(item);
                    if (coordinate == null) continue;

                    stops.add(
                      RouteStop(
                        name: _destinationName(item),
                        coordinate: coordinate,
                        // Index yang sama dengan _buildMarkers, supaya
                        // heatmap yang tampil di RouteScreen (full map)
                        // konsisten dengan yang di peta preview ini.
                        crowdStatus: _getCrowdStatus(item, i),
                      ),
                    );
                  }

                  if (stops.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Koordinat destinasi hari ini belum tersedia, jadi rute belum bisa ditampilkan.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteScreen(
                        stops: stops,
                        initialVehicle: vehicle,
                        onStopIndexChanged: (index) {
                          if (!mounted) return;
                          setState(() {
                            _completedStopIndex = index;
                          });
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Rute',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // TODO(fungsi bertahap): teks statis, belum dihitung dari
          // jam sekarang vs jam keberangkatan sebenarnya.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time_rounded, size: 15, color: AppColors.darkBlue),
                SizedBox(width: 6),
                Text(
                  'Estimasi keberangkatan 30 menit lagi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRIP SWITCHER (jika ada lebih dari 1 trip aktif)
  // ============================================================

  Widget _buildTripSwitcher(
    BuildContext context,
    List<List<Map<String, dynamic>>> activeTrips,
    int currentIndex,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perjalanan Aktif ${currentIndex + 1} dari ${activeTrips.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activeTrips[currentIndex].isNotEmpty
                      ? (activeTrips[currentIndex].first['tripName'] ?? 'Trip ${currentIndex + 1}')
                      : 'Trip ${currentIndex + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlue,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              _showTripSelectorBottomSheet(context, activeTrips, currentIndex);
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ganti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTripSelectorBottomSheet(
    BuildContext context,
    List<List<Map<String, dynamic>>> activeTrips,
    int currentIndex,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D8D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'Pilih Perjalanan Aktif',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih perjalanan yang ingin kamu lihat rutenya hari ini.',
                style: TextStyle(fontSize: 12, color: AppColors.greyText),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeTrips.length,
                  itemBuilder: (context, index) {
                    final trip = activeTrips[index];
                    final String name = trip.isNotEmpty ? (trip.first['tripName'] ?? 'Trip ${index + 1}') : 'Trip ${index + 1}';
                    final String destination = trip.isNotEmpty ? (trip.first['destination'] ?? '') : '';
                    final bool isSelected = index == currentIndex;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        setState(() {
                          _selectedActiveTripIndex = index;
                          _selectedDayNumber = null;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.lightBlue : const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryBlue : const Color(0xFFEEEEEE),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? AppColors.primaryBlue : AppColors.greyText,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? AppColors.darkBlue : AppColors.darkText,
                                    ),
                                  ),
                                  if (destination.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      destination,
                                      style: const TextStyle(fontSize: 12, color: AppColors.greyText),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // CHANGED - padding menyesuaikan font yang lebih besar
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Aktif',
                                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold), // CHANGED - font terkecil jadi 12
                                ),
                              ),
                          ],
                        ),
                      ),
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

  // ============================================================
  // INFO TRIP (judul, tanggal, peserta, kendaraan, hari ke-, dsb)
  // ============================================================

  String _formatDateRange(dynamic start, dynamic end) {
    if (start is! DateTime || end is! DateTime) return '';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    final String startText = '${start.day} ${months[start.month - 1]}';
    final String endText = '${end.day} ${months[end.month - 1]} ${end.year}';

    return '$startText-$endText';
  }

  Widget _buildTripInfo(
    Map<String, dynamic> schedule,
    int dayNumber,
    int totalDays, {
    required bool isDayCompleted,
  }) {
    final String tripName = _value(schedule, 'tripName', fallback: 'Trip');
    final String destination = _value(schedule, 'destination');
    final String participants = _value(schedule, 'participants', fallback: '-');
    final String vehicle = _value(schedule, 'vehicle', fallback: '-');
    final String dateRange = _formatDateRange(schedule['startDate'], schedule['endDate']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tripName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkText),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.greyText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                dateRange.isNotEmpty ? dateRange : 'Tanggal perjalanan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.greyText),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.people_outline, size: 17, color: AppColors.greyText),
            const SizedBox(width: 5),
            Text('$participants Orang', style: const TextStyle(fontSize: 12, color: AppColors.greyText)),
            const SizedBox(width: 14),
            const Icon(Icons.directions_car_outlined, size: 17, color: AppColors.greyText),
            const SizedBox(width: 5),
            Text(vehicle, style: const TextStyle(fontSize: 12, color: AppColors.greyText)),
          ],
        ),

        if (destination.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 17, color: AppColors.darkBlue),
                const SizedBox(width: 6),
                Text(
                  destination,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkBlue),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        Row(
          children: [
            Text(
              'Hari ke-$dayNumber dari $totalDays hari',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                // Hijau muda kalau hari yang ditampilkan sudah
                // selesai, biru muda (gaya lama) kalau masih berjalan
                // -- supaya beda status kelihatan jelas di badge.
                color: isDayCompleted ? const Color(0xFFE6F7EC) : AppColors.lightBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isDayCompleted ? 'Selesai' : 'Sedang Berjalan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDayCompleted ? const Color(0xFF1E8E4F) : AppColors.darkBlue,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Day switcher -- gaya sama dengan _buildDayTabs di
        // ItineraryDetailScreen (pill horizontal, aktif = biru
        // penuh). Aktif & sinkron: pindah tab ganti destinasi,
        // jadwal, peta, dan progress yang ditampilkan (lihat
        // _selectDay & _buildActiveTrip). Menggantikan chevron
        // panah yang sebelumnya ada di sini -- sudah tidak
        // navigasi ke layar lain jadi dihapus.
        //
        // startDate dikirim supaya _buildDayTabs bisa menghitung
        // tanggal kalender tiap hari (startDate + (day-1)) dan
        // mengunci ("off") hari yang tanggalnya belum tiba -- lihat
        // komentar lengkap di _buildDayTabs.
        _buildDayTabs(dayNumber, totalDays, schedule['startDate']),
      ],
    );
  }

  // ============================================================
  // DAY TABS -- gaya sama dengan ItineraryDetailScreen._buildDayTabs
  // ============================================================
  //
  // Pill horizontal yang bisa di-scroll, satu per hari trip (1..
  // totalDays). Tap ganti hari yang ditampilkan lewat _selectDay --
  // aktif & sinkron ke seluruh layar (jadwal, peta, progress).
  //
  // HARI YANG BELUM WAKTUNYA DIKUNCI ("OFF"):
  // Trip 3 hari yang baru jalan di Hari 1 seharusnya tidak bisa
  // "loncat" ke tab Hari 2/3 dan menandai destinasi di situ sebagai
  // sudah dikunjungi lewat RouteScreen -- itu bakal salah nampilin
  // progress (dan bisa keliru memicu _buildFinishDayCard di hari
  // yang belum benar-benar dijalani). Makanya tab hari yang tanggal
  // kalendernya (startDate + (day-1)) masih SETELAH hari ini dikunci:
  // dikasih gaya abu-abu + ikon gembok, dan tap-nya cuma munculin
  // SnackBar info tanggalnya, TIDAK memanggil _selectDay.
  //
  // ============================================================

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _buildDayTabs(int selectedDay, int totalDays, dynamic startDate) {
    if (totalDays <= 1) return const SizedBox();

    // null kalau startDate tidak valid -- dianggap TIDAK ada hari yang
    // dikunci daripada salah mengunci semua hari akibat data yang
    // belum lengkap.
    final DateTime? start = startDate is DateTime ? _dateOnly(startDate) : null;
    final DateTime today = _dateOnly(DateTime.now());

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final int day = index + 1;
          final bool selected = day == selectedDay;

          final DateTime? dayDate = start?.add(Duration(days: day - 1));
          final bool isLocked = dayDate != null && dayDate.isAfter(today);

          return GestureDetector(
            onTap: () {
              if (isLocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Hari $day belum bisa dibuka -- jadwalnya tanggal ${_formatShortDate(dayDate)}',
                    ),
                  ),
                );
                return;
              }

              _selectDay(day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryBlue
                    : (isLocked ? const Color(0xFFF7F7F7) : const Color(0xFFF1F1F1)),
                borderRadius: BorderRadius.circular(19),
                border: isLocked ? Border.all(color: const Color(0xFFE3E3E3)) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLocked) ...[
                    const Icon(Icons.lock_outline, size: 12, color: Color(0xFFAFAFAF)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Hari $day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : (isLocked ? const Color(0xFFAFAFAF) : AppColors.greyText),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PROGRES HARI INI
  // ============================================================
  //
  // Jumlah SELESAI sekarang diterima lewat effectiveCompletedIndex
  // dari _buildActiveTrip -- gabungan antara _completedStopIndex
  // (progress ephemeral dari callback onStopIndexChanged RouteScreen)
  // dan status 'dayCompleted' yang dipersist (kalau hari ini memang
  // sudah selesai, dianggap 100% terlepas dari _completedStopIndex).
  // Di-clamp ke destinations.length supaya aman kalau daftar destinasi
  // hari ini berubah (mis. ganti hari). Jumlah TOTAL tetap ambil data
  // asli dari destinations.length.
  //
  // ============================================================

  Widget _buildProgressCard(
    List<Map<String, dynamic>> destinations,
    int effectiveCompletedIndex,
  ) {
    final int total = destinations.length;
    final int completed = effectiveCompletedIndex.clamp(0, total);
    final double progress = total == 0 ? 0 : completed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres Hari Ini',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed/$total aktivitas selesai',
            style: const TextStyle(fontSize: 12, color: AppColors.greyText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEDEDED),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()} %',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU "TANDAI HARI INI SELESAI"
  // ============================================================
  //
  // Muncul menggantikan kartu "Aktivitas Berikutnya" yang hilang
  // begitu semua destinasi HARI YANG SEDANG DITAMPILKAN sudah
  // "off"/dikunjungi -- lihat showFinishDayCard di _buildActiveTrip.
  // Sekarang bisa muncul di hari mana pun (bukan cuma hari terakhir),
  // karena statusnya per-hari. Tombolnya memanggil _markDayFinished,
  // yang menyimpan status selesai HANYA untuk hari ini (bukan seluruh
  // itinerary) lewat SavedItineraryService.markDayCompleted, supaya:
  // - Badge di _buildTripInfo berubah jadi "Selesai" untuk hari ini,
  // - HistoryScreen.hasAnyCompletedDay ikut mengenalinya sehingga
  //   itinerary ini langsung ikut muncul di Riwayat, TAPI
  // - Hari-hari lain (termasuk hari berikutnya yang belum tiba
  //   tanggalnya) TIDAK ikut ditandai -- begitu tanggalnya tiba,
  //   TripScreen tetap menganggap itinerary ini aktif untuk hari itu
  //   (lihat _findActiveTrip yang sudah tidak skip berdasarkan flag
  //   apa pun di level itinerary).
  //
  // ============================================================

  Widget _buildFinishDayCard(
    List<Map<String, dynamic>> itinerary,
    int dayNumber, {
    required bool isLastDay,
    bool allDone = false,
  }) {
    final String title = allDone
        ? 'Semua destinasi hari ini sudah dikunjungi!'
        : 'Selesaikan Perjalanan Hari Ke-$dayNumber';

    final String subtitle = isLastDay
        ? 'Tandai selesai di sini supaya trip ini pindah ke tab Riwayat.'
        : 'Tandai hari ini selesai -- trip ini akan dicatat di Riwayat dan siap untuk hari berikutnya.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration_outlined, color: AppColors.darkBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => _markDayFinished(context, itinerary, dayNumber, isLastDay: isLastDay),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: Text(
                isLastDay ? 'Tandai Trip Selesai' : 'Tandai Hari Ini Selesai',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markDayFinished(
    BuildContext context,
    List<Map<String, dynamic>> itinerary,
    int dayNumber, {
    required bool isLastDay,
  }) {
    final String? itineraryId = SavedItineraryService.instance.itineraryIdOf(itinerary);

    // ==============================================================
    // BENTUK POPUP DISAMAKAN dengan popup "Itinerary berhasil
    // dibuat!" di ItineraryPreviewScreen: Dialog putih sudut 22,
    // ikon lingkaran di atas, judul tebal, tombol utama penuh
    // (rounded 25), tombol teks di bawahnya.
    // ==============================================================

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ----------------------------------------------
                // IKON
                // ----------------------------------------------
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: AppColors.primaryBlue,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------
                // JUDUL
                // ----------------------------------------------
                Text(
                  'Selesaikan Hari ke-$dayNumber?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),

                const SizedBox(height: 10),

                // ----------------------------------------------
                // DESKRIPSI
                // ----------------------------------------------
                Text(
                  isLastDay
                      ? 'Trip ini akan ikut ditampilkan di Riwayat.'
                      : 'Hari ke-$dayNumber akan ditandai selesai dan trip ini ikut ditampilkan di Riwayat. Hari berikutnya tetap akan aktif normal di tab Trip begitu tanggalnya tiba.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.greyText,
                  ),
                ),

                const SizedBox(height: 22),

                // ----------------------------------------------
                // YA, SELESAI
                // ----------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (itineraryId != null) {
                        SavedItineraryService.instance.markDayCompleted(itineraryId, dayNumber);
                      }

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hari ini telah ditandai selesai dan ikut masuk ke Riwayat'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Ya, Selesai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ----------------------------------------------
                // BATAL
                // ----------------------------------------------
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TIMELINE HARI INI
  // ============================================================

  Widget _buildTimelineDot({required bool isLast, required bool isDone}) {
    // isDone (sudah dilewati) pakai AppColors.doneGrey, sama pola warna "off"
    // dengan leg yang sudah dilewati di RouteScreen -- lihat
    // RouteScreen.doneGrey.
    final Color dotColor = isDone ? AppColors.doneGrey : AppColors.primaryBlue;

    return SizedBox(
      width: 30,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: dotColor, width: 3),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: AppColors.doneGrey)
                  : CircleAvatar(radius: 5, backgroundColor: dotColor),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(width: 2, color: dotColor.withValues(alpha: 0.55)),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationRow({
    required int index,
    required Map<String, dynamic> destination,
    required bool isLast,
    required bool isDone,
  }) {
    final name = _destinationName(destination);
    final image = _destinationImage(destination);
    final arrival = _arrivalTime(destination);
    final departure = _departureTime(destination);
    final duration = _calculateDuration(arrival, departure);
    final crowdStatus = _getCrowdStatus(destination, index);

    // Warna teks & kartu dibikin pudar (abu-abu) kalau destinasi ini
    // sudah dilewati -- gaya "off", senada dengan leg abu-abu di
    // RouteScreen.
    final Color nameColor = isDone ? AppColors.greyText : AppColors.darkText;
    final Color cardBorderColor = isDone ? AppColors.doneGrey : AppColors.borderColor;

    return Opacity(
      opacity: isDone ? 0.6 : 1,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimelineDot(isLast: isLast, isDone: isDone),
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 6, 0, isLast ? 0 : 20),
              child: SizedBox(
                width: 68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$arrival - $departure',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nameColor),
                    ),
                    const SizedBox(height: 6),
                    _buildCrowdLabel(crowdStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SmartImage(
                            imagePathOrUrl: image,
                            width: 62,
                            height: 62,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: nameColor),
                              ),
                              if (isDone) ...[
                                const SizedBox(height: 4),
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 12, color: AppColors.doneGrey),
                                    SizedBox(width: 4),
                                    Text(
                                      'Sudah dikunjungi',
                                      style: TextStyle(fontSize: 12, color: AppColors.doneGrey, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ] else if (duration.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(duration, style: const TextStyle(fontSize: 12, color: AppColors.greyText)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTimeline(
    Map<String, dynamic> schedule,
    List<Map<String, dynamic>> destinations,
    int effectiveCompletedIndex,
  ) {
    if (destinations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Belum ada aktivitas untuk hari ini',
          style: TextStyle(fontSize: 14, color: AppColors.greyText),
        ),
      );
    }

    return Column(
      children: List.generate(destinations.length, (index) {
        return _buildDestinationRow(
          index: index,
          destination: destinations[index],
          isLast: index == destinations.length - 1,
          // Destinasi dengan index < effectiveCompletedIndex berarti
          // sudah "Ditandai Sudah Sampai" di RouteScreen ATAU harinya
          // sudah dipersist selesai (lihat effectiveCompletedIndex di
          // _buildActiveTrip) -- dikasih gaya "off" (abu-abu/tercentang),
          // lihat _buildTimelineDot & style di bawah.
          isDone: index < effectiveCompletedIndex,
        );
      }),
    );
  }

  // ============================================================
  // BANNER PERINGATAN KEPADATAN
  // ============================================================

  Widget _buildCrowdWarning(Map<String, dynamic> destination) {
    final String name = _destinationName(destination);
    final String arrival = _arrivalTime(destination);
    final String departure = _departureTime(destination);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: warnBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: warnText),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: warnText, height: 1.4),
                children: [
                  TextSpan(text: '$name ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: 'diprediksi ramai pada pukul $arrival - $departure'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PANEL "PENYESUAIAN ITINERARY"
  // ============================================================
  //
  // TODO(fungsi bertahap): sekarang cuma bisa dipilih (UI state),
  // "Terapkan Perubahan" belum ngejalanin logic apa pun.
  //
  // ============================================================

  Widget _buildAdjustmentPanel(int totalDays) {
    final List<Map<String, String>> options = _adjustmentOptionsFor(totalDays);

    // Jaga-jaga kalau index yang lagi dipilih jadi di luar rentang
    // opsi baru (mis. pernah pilih "Pindah ke hari lain" pas trip
    // multi-hari, terus totalDays berubah) -- fallback ke opsi
    // pertama biar gak index-out-of-range.
    final int selectedIndex = _selectedAdjustment < options.length ? _selectedAdjustment : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penyesuaian Itinerary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText),
        ),
        const SizedBox(height: 12),
        ...List.generate(options.length, (index) {
          final option = options[index];
          final bool selected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAdjustment = index;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.lightBlue : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primaryBlue : AppColors.borderColor,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['title']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.darkBlue : AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option['subtitle']!,
                      style: const TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur penyesuaian itinerary akan tersedia di update berikutnya'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Terapkan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}