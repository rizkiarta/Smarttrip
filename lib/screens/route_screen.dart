import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

// ================================================================
// ROUTE SCREEN (MULTI-STOP) -- RUTE JALAN ASLI (GAYA NAVIGASI)
// ================================================================
//
// RIWAYAT SINGKAT revisi layar ini (biar jelas kenapa kodenya begini):
// 1. Awalnya: rute jalan asli dari OSRM, garis mengikuti jalan.
// 2. Sempat diganti ke garis LURUS putus-putus (gaya
//    ItineraryDetailScreen) + jarak haversine, supaya tidak perlu
//    fetch OSRM lagi.
// 3. SEKARANG DIBALIKIN LAGI ke rute jalan asli -- garis lurus
//    dianggap kurang cocok untuk layar navigasi, jarak & bentuk
//    garisnya harus benar-benar mengikuti jalan (seperti aplikasi
//    navigasi beneran), jadi OSRM dipakai lagi.
//
// YANG TETAP DIPERTAHANKAN dari revisi #2 (TIDAK di-revert):
// - Gaya PIN bernomor: ikon lokasi + badge angka kecil di pojok
//   kanan-atas pin (bukan lagi lingkaran polos berisi angka/centang
//   seperti versi #1) -- ini permintaan terpisah dari soal jarak, dan
//   masih relevan dipakai bareng rute jalan asli.
//
// YANG DIPERTAHANKAN dari versi #1 & TIDAK PERNAH diubah sejak awal:
// - Perilaku ON/OFF/PROGRESS: _currentStopIndex tetap state LOKAL
//   layar ini, dimajukan lewat tombol "Tandai Sudah Sampai". Leg
//   yang sedang dituju ("on") tebal & biru gelap, leg berikutnya
//   ("off") tipis & biru muda, leg yang sudah dilewati abu-abu.
//
// 6. SEKARANG DISAMBUNGKAN ke TripScreen lewat callback
//    `onStopIndexChanged` (dipanggil tiap _markArrived berhasil
//    majuin _currentStopIndex) -- supaya kartu "Progres Hari Ini"
//    dan timeline di TripScreen ikut gerak begitu user kembali ke
//    layar itu. Ini state biasa (bukan disimpan permanen ke
//    SavedItineraryService) -- reset kalau TripScreen di-dispose
//    total (mis. app ditutup), sesuai keputusan yang diambil.
// - Titik awal SELALU dari lokasi GPS user saat ini (Geolocator),
//   bukan startLatitude/startLongitude statis.
//
// 4. PILIHAN MODE KENDARAAN diubah: "Jalan Kaki" DIHAPUS, diganti
//    "Motor" dan "Bus" -- jadi sekarang ada 3 pilihan: Mobil / Motor
//    / Bus. Konsekuensi teknis (WAJIB dibaca sebelum ubah logic
//    fetch OSRM di bawah): server demo publik OSRM
//    (router.project-osrm.org) HANYA punya profil routing 'driving'
//    -- tidak ada profil motor atau bus terpisah. Jadi di balik
//    layar, KETIGA mode ini sama-sama pakai profil 'driving' yang
//    sama; bedanya PURE di tampilan (ikon & label tombol yang aktif),
//    bukan di rute yang dihitung. Kalau nanti pindah ke server
//    routing sendiri yang punya profil motor/bus terpisah, tinggal
//    ubah _osrmProfile di bawah supaya benar-benar berbeda per mode.
//    Karena rutenya sama persis, ganti mode TIDAK memicu fetch ulang
//    ke OSRM (lihat _changeTravelMode) -- cuma ganti tombol mana yang
//    kelihatan aktif.
//
// 5. MODE AKTIF AWAL sekarang otomatis mengikuti data kendaraan yang
//    SUDAH DIISI user untuk trip ini (field 'vehicle' dari
//    TravelInformationScreen, dikirim TripScreen lewat parameter
//    `initialVehicle`) -- BUKAN selalu default ke "Mobil" seperti
//    sebelumnya. User tetap bisa ganti manual lewat toggle di kartu
//    bawah kalau mau lihat estimasi mode lain.
//
// CATATAN OSRM sama seperti dulu: endpoint demo gratis, cocok untuk
// pengembangan/skripsi, bukan untuk beban produksi.
// ================================================================

class RouteStop {
  final String name;
  final LatLng coordinate;

  // Status kepadatan ('Ramai'/'Sedang'/'Sepi') destinasi ini --
  // dikirim dari layar pemanggil (TripScreen/ItineraryDetailScreen)
  // supaya heatmap yang tampil di sini KONSISTEN dengan yang di peta
  // preview kedua layar itu, bukan dihitung ulang terpisah. Boleh
  // null (heatmap-nya cuma disembunyikan untuk stop itu) supaya
  // pemanggil lama yang belum ngirim data ini tidak error.
  final String? crowdStatus;

  const RouteStop({
    required this.name,
    required this.coordinate,
    this.crowdStatus,
  });
}

class RouteScreen extends StatefulWidget {
  final List<RouteStop> stops;

  // Label kendaraan ASLI dari data trip (field 'vehicle' yang diisi
  // user di TravelInformationScreen, mis. "Mobil", "Motor", "Bus").
  // Dipakai sekali di initState untuk menentukan mode kendaraan AKTIF
  // saat layar ini pertama dibuka, supaya sesuai kendaraan yang
  // memang sudah dipilih user untuk trip ini -- lihat
  // _resolveInitialTravelMode. Boleh null/kosong/nilai yang tidak
  // dikenali -- fallback ke Mobil.
  final String? initialVehicle;

  // Dipanggil tiap _currentStopIndex maju (lewat tombol "Tandai
  // Sudah Sampai") -- lihat _markArrived. Dikirim TripScreen supaya
  // kartu "Progres Hari Ini" & timeline di sana ikut gerak. Opsional
  // (null aman) supaya RouteScreen tetap bisa dipakai berdiri
  // sendiri tanpa parent yang peduli progress.
  final ValueChanged<int>? onStopIndexChanged;

  // ==============================================================
  // MODE READ-ONLY (dipakai ItineraryDetailScreen)
  // ==============================================================
  //
  // Dipakai saat RouteScreen ditampilkan sebagai GAMBARAN rute
  // (preview sebelum trip berjalan), bukan navigasi aktif:
  // - startCoordinate: titik awal yang SUDAH diketahui dari data
  //   itinerary (mis. startLatitude/startLongitude dari
  //   TravelInformationScreen), dipakai MENGGANTI lokasi GPS user
  //   saat ini -- supaya layar ini tidak perlu izin lokasi/GPS sama
  //   sekali kalau trip belum berjalan.
  // - readOnly: kalau true, tombol "Tandai Sudah Sampai" di kartu
  //   info bawah disembunyikan (lihat _buildBottomInfoCard) --
  //   layar ini murni menampilkan bentuk rute, tidak ada progress
  //   yang bisa ditandai/dikirim balik lewat onStopIndexChanged.
  //
  // ==============================================================

  final LatLng? startCoordinate;
  final bool readOnly;

  const RouteScreen({
    super.key,
    required this.stops,
    this.initialVehicle,
    this.onStopIndexChanged,
    this.startCoordinate,
    this.readOnly = false,
  }) : assert(stops.length > 0, 'RouteScreen butuh minimal 1 stop');

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

enum _TravelMode { car, motorcycle, bus }

class _RouteLeg {
  // Titik-titik geometri rute ASLI dari OSRM (mengikuti bentuk
  // jalan) -- bukan cuma 2 titik lurus seperti versi garis-lurus.
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  _RouteLeg({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class _RouteScreenState extends State<RouteScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color offBlue = AppColors.paleBlue; // leg "off"

  // Warna khusus marker titik keberangkatan (lokasi GPS user) --
  // senada dengan warna marker "Lokasi Awal" di ItineraryDetailScreen
  // supaya bahasa visualnya konsisten antar layar.
  static const Color homeGreen = AppColors.successGreen;

  // ============================================================
  // CROWD HEATMAP DOTS (DI PETA)
  // ============================================================
  //
  // Sama persis gaya & logikanya dengan
  // ItineraryDetailScreen._buildCrowdHeatmapDots/_crowdText --
  // gumpalan titik warna-warni di sekitar pin stop (merah = Ramai,
  // kuning = Sedang, hijau = Sepi), posisinya di-generate pakai
  // Random(seed) supaya stabil (bukan acak tiap rebuild). Beda
  // dengan versi ItineraryDetailScreen/TripScreen: di sini datanya
  // dari RouteStop.crowdStatus yang sudah dikirim pemanggil, bukan
  // dihitung ulang dari Map destinasi (RouteStop cuma punya
  // name+coordinate).
  //
  // ============================================================

  Color _crowdDotColor(String status) {
    switch (status) {
      case 'Ramai':
        return  AppColors.errorRed;
      case 'Sedang':
        return  AppColors.warningText;
      default:
        return const Color(0xFF20A447);
    }
  }

  Widget _buildCrowdHeatmapDots(String status, int seed) {
    final Color color = _crowdDotColor(status);

    final int dotCount = switch (status) {
      'Ramai' => 22,
      'Sedang' => 15,
      _ => 10,
    };

    final math.Random random = math.Random(seed);

    const double size = 80;
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

  // ============================================================
  // STATE
  // ============================================================

  final MapController _mapController = MapController();

  bool _isLoading = true;
  String? _errorMessage;

  LatLng? _currentLocation;

  // Satu leg per stop: _legs[0] = lokasi user -> stops[0],
  // _legs[1] = stops[0] -> stops[1], dst. Panjang list ini selalu
  // sama dengan widget.stops.length. null berarti leg itu gagal
  // diambil (mis. OSRM tidak nemu rute) -- tidak bikin semua leg
  // lain ikut gagal.
  List<_RouteLeg?> _legs = [];

  // Index stop yang lagi DITUJU sekarang (0-based). Ini yang
  // menentukan leg mana yang "on" (tebal/gelap) -- lihat komentar
  // di atas class.
  int _currentStopIndex = 0;

  // Diisi di initState lewat _resolveInitialTravelMode -- BUKAN
  // langsung di-default ke Mobil seperti sebelumnya, supaya mode
  // aktif awal sesuai kendaraan yang sudah dipilih user untuk trip
  // ini (lihat widget.initialVehicle). late karena nilainya baru
  // pasti ada setelah dihitung di initState.
  late _TravelMode _travelMode;

  @override
  void initState() {
    super.initState();
    _travelMode = _resolveInitialTravelMode(widget.initialVehicle);
    _loadAllLegs();
  }

  // ============================================================
  // TENTUKAN MODE KENDARAAN AKTIF AWAL DARI DATA TRIP
  // ============================================================
  //
  // Dicocokkan pakai 'contains' (bukan '==' persis) supaya tahan
  // terhadap variasi penulisan yang mungkin diisi user/data lama,
  // mis. "Sepeda Motor", "Motor Pribadi", "Bus Pariwisata", dst --
  // bukan cuma persis "Motor"/"Bus". Kalau tidak cocok sama sekali
  // (kosong, null, atau nilai tak dikenal seperti "Mobil"), fallback
  // ke _TravelMode.car.
  //
  // ============================================================

  _TravelMode _resolveInitialTravelMode(String? vehicleLabel) {
    final String normalized = (vehicleLabel ?? '').trim().toLowerCase();

    if (normalized.contains('motor')) return _TravelMode.motorcycle;
    if (normalized.contains('bus')) return _TravelMode.bus;

    return _TravelMode.car;
  }

  // ============================================================
  // MUAT SEMUA LEG (lokasi user -> stop 1 -> stop 2 -> ...)
  // ============================================================

  Future<void> _loadAllLegs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Kalau startCoordinate sudah dikasih (mode readOnly dari
      // ItineraryDetailScreen), pakai itu langsung sebagai titik
      // awal -- TIDAK perlu minta izin/lokasi GPS sama sekali.
      // Geolocator cuma dipanggil kalau memang tidak ada titik awal
      // yang sudah diketahui (mode navigasi aktif dari TripScreen).
      final LatLng origin;

      if (widget.startCoordinate != null) {
        origin = widget.startCoordinate!;
      } else {
        final currentPosition = await _determineCurrentPosition();
        origin = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
      }

      final List<_RouteLeg?> legs = [];
      LatLng legOrigin = origin;

      for (final stop in widget.stops) {
        try {
          final leg = await _fetchLeg(
            origin: legOrigin,
            destination: stop.coordinate,
          );
          legs.add(leg);
        } catch (_) {
          // Satu leg gagal (mis. OSRM tidak nemu rute jalan kaki di
          // lokasi itu) tidak boleh bikin seluruh rute multi-stop
          // ikut gagal -- leg lain tetap dicoba.
          legs.add(null);
        }

        // Leg berikutnya dihitung dari titik stop ini, TERLEPAS
        // dari leg di atas berhasil atau tidak, supaya urutan rute
        // tetap sesuai jadwal.
        legOrigin = stop.coordinate;
      }

      if (!mounted) return;

      setState(() {
        _currentLocation = origin;
        _legs = legs;
        _isLoading = false;
      });

      _fitCameraToAll();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // LOKASI PENGGUNA SAAT INI
  // ============================================================

  Future<Position> _determineCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Aktifkan GPS terlebih dahulu untuk melihat rute.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi diperlukan untuk menampilkan rute ke destinasi.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ============================================================
  // AMBIL SATU LEG RUTE DARI OSRM
  // ============================================================

  Future<_RouteLeg> _fetchLeg({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // Profil OSRM SELALU 'driving' -- lihat catatan besar di atas
    // class ini kenapa Mobil/Motor/Bus tidak punya profil routing
    // terpisah di server demo publik.
    const profile = 'driving';

    // OSRM format koordinat: lon,lat (kebalikan dari LatLng)
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';

    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/$coordinates'
      '?overview=full&geometries=geojson',
    );

    final response = await http.get(uri).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data rute. Coba lagi.');
    }

    final data = jsonDecode(response.body);

    if (data['code'] != 'Ok' ||
        data['routes'] == null ||
        (data['routes'] as List).isEmpty) {
      throw Exception('Rute tidak ditemukan untuk lokasi ini.');
    }

    final route = data['routes'][0];

    final List<dynamic> rawCoords = route['geometry']['coordinates'];

    final points = rawCoords.map<LatLng>((c) {
      // GeoJSON: [lon, lat]
      return LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      );
    }).toList();

    return _RouteLeg(
      points: points,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }

  // ============================================================
  // FIT CAMERA supaya SELURUH rute (semua leg) terlihat di layar
  // ============================================================

  void _fitCameraToAll() {
    final List<LatLng> allPoints = [];

    for (final leg in _legs) {
      if (leg != null) allPoints.addAll(leg.points);
    }

    if (allPoints.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(allPoints);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 120, 40, 260),
        ),
      );
    });
  }

  // ============================================================
  // GANTI MODE KENDARAAN (Mobil / Motor / Bus)
  // ============================================================
  //
  // TIDAK fetch ulang ke OSRM -- lihat catatan profil OSRM di atas
  // class ini, server demo publik cuma punya profil 'driving', jadi
  // Mobil/Motor/Bus semua menghasilkan rute yang identik. Ganti mode
  // di sini murni ganti tampilan (tombol mana yang aktif), bukan
  // mengubah rute yang ditampilkan.
  //
  // ============================================================

  void _changeTravelMode(_TravelMode mode) {
    if (_travelMode == mode) return;

    setState(() {
      _travelMode = mode;
    });
  }

  // ============================================================
  // TANDAI SUDAH SAMPAI DI STOP YANG SEDANG DITUJU
  // ============================================================
  //
  // Majuin _currentStopIndex satu langkah -- leg yang tadinya "off"
  // (menuju stop berikutnya) sekarang jadi "on", dan leg yang baru
  // saja dilewati jadi abu-abu (selesai). Tidak perlu fetch ulang
  // ke OSRM karena semua leg sudah dihitung sekaligus di awal --
  // cuma ganti warna/tampilan.
  //
  // _currentStopIndex sekarang boleh sampai widget.stops.length
  // (bukan cuma stops.length - 1 seperti sebelumnya) -- itu artinya
  // SEMUA stop, termasuk yang TERAKHIR, sudah ditandai "Sudah
  // Sampai". Sebelumnya destinasi terakhir gak pernah bisa "off"
  // karena tombolnya selalu disabled di stop terakhir.
  //
  // ============================================================

  void _markArrived() {
    if (_currentStopIndex >= widget.stops.length) return;

    setState(() {
      _currentStopIndex++;
    });

    // Kasih tau parent (TripScreen) supaya progress card & timeline
    // di sana ikut gerak -- lihat komentar widget.onStopIndexChanged.
    widget.onStopIndexChanged?.call(_currentStopIndex);
  }

  Color _legColor(int index) {
    if (index < _currentStopIndex) return AppColors.doneGrey;
    if (index == _currentStopIndex) return AppColors.primaryBlue;
    return offBlue;
  }

  double _legWidth(int index) {
    return index == _currentStopIndex ? 5 : 3.5;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ====================================================
            // MAP / LOADING / ERROR
            // ====================================================

            Positioned.fill(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildMap(),
            ),

            // ====================================================
            // HEADER
            // ====================================================

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(),
            ),

            // ====================================================
            // BOTTOM INFO CARD (jarak, waktu tempuh, progres stop)
            // ====================================================

            if (!_isLoading && _errorMessage == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomInfoCard(),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  String get _headerTitle {
    if (widget.stops.length == 1) {
      return 'Rute ke ${widget.stops.first.name}';
    }
    return 'Rute Hari Ini (${widget.stops.length} Destinasi)';
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const SizedBox(
              width: 45,
              height: 45,
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.darkText,
                size: 21,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _headerTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(width: 45),
        ],
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    // --------------------------------------------------------
    // GARIS RUTE: mengikuti geometri jalan ASLI dari OSRM (bukan
    // garis lurus lagi) -- solid, bukan putus-putus, supaya terasa
    // seperti tampilan navigasi. Warna & ketebalan tetap ikut status
    // on/off/sudah dilewati (_legColor / _legWidth), TIDAK berubah
    // dari sebelumnya.
    // --------------------------------------------------------

    final List<Polyline> polylines = [];

    for (int i = 0; i < _legs.length; i++) {
      final leg = _legs[i];
      if (leg == null || leg.points.length < 2) continue;

      polylines.add(
        Polyline(
          points: leg.points,
          strokeWidth: _legWidth(i),
          color: _legColor(i),
          borderStrokeWidth: i == _currentStopIndex ? 1.5 : 0,
          borderColor: AppColors.darkBlue,
        ),
      );
    }

    final List<Marker> markers = [];

    // --------------------------------------------------------
    // TITIK AWAL (lokasi GPS user saat ini) -- gaya lingkaran +
    // stick kecil di bawah, senada dengan marker "Lokasi Awal" di
    // ItineraryDetailScreen, tapi tetap pakai ikon lokasi-langsung
    // (bukan ikon rumah) karena ini posisi GPS real-time, bukan
    // alamat tetap.
    // --------------------------------------------------------

    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 42,
          height: 54,
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: homeGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              Container(
                width: 3,
                height: 10,
                color: homeGreen,
              ),
            ],
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // PIN BERNOMOR PER STOP -- ikon lokasi + badge nomor urut kecil
    // di pojok kanan-atas, gaya sama seperti pin destinasi di
    // ItineraryDetailScreen (dipertahankan dari revisi sebelumnya).
    // Warna pin (bulatan besarnya) TETAP mengikuti status
    // on/off/sudah dilewati seperti sedari awal.
    // --------------------------------------------------------

    for (int i = 0; i < widget.stops.length; i++) {
      final bool passed = i < _currentStopIndex;
      final bool active = i == _currentStopIndex;

      final Color pinColor = passed
          ? AppColors.doneGrey
          : active
              ? AppColors.darkBlue
              : offBlue;

      // Heatmap kepadatan -- ditambahkan SEBELUM pin nomornya (biar
      // ada di lapisan bawah, sama seperti di ItineraryDetailScreen/
      // TripScreen). Dilewati kalau stop ini tidak bawa crowdStatus
      // (mis. dipanggil dari kode lama yang belum ngirim data itu).
      final String? crowdStatus = widget.stops[i].crowdStatus;
      if (crowdStatus != null) {
        final int dotSeed =
            widget.stops[i].name.codeUnits.fold<int>(0, (sum, code) => sum + code) + i;

        markers.add(
          Marker(
            point: widget.stops[i].coordinate,
            width: 80,
            height: 80,
            child: _buildCrowdHeatmapDots(crowdStatus, dotSeed),
          ),
        );
      }

      markers.add(
        Marker(
          point: widget.stops[i].coordinate,
          width: 42,
          height: 54,
          child: Column(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: pinColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        passed ? Icons.check_rounded : Icons.location_on,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 17,
                        height: 17,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: pinColor,
                            width: 1.4,
                          ),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: pinColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 3,
                height: 10,
                color: pinColor,
              ),
            ],
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // LABEL DURASI ("x mnt") di tengah tiap leg -- balik memakai
    // durasi ASLI dari OSRM (bukan label jarak garis lurus lagi),
    // sesuai referensi navigasi.
    // --------------------------------------------------------

    for (int i = 0; i < _legs.length; i++) {
      final leg = _legs[i];
      if (leg == null || leg.points.isEmpty) continue;

      final LatLng midPoint = leg.points[leg.points.length ~/ 2];
      final int minutes = (leg.durationSeconds / 60).round();
      final bool active = i == _currentStopIndex;

      markers.add(
        Marker(
          point: midPoint,
          width: 72,
          height: 30,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.darkBlue : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _legColor(i)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '$minutes mnt',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.darkText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? widget.stops.first.coordinate,
        initialZoom: 14,
        minZoom: 4,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.smarttrip',
        ),

        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),

        MarkerLayer(markers: markers),

        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
            TextSourceAttribution('CARTO'),
            TextSourceAttribution('Routing by OSRM (demo server)'),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.greyText),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadAllLegs,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.darkBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM INFO CARD
  // ============================================================

  Widget _buildBottomInfoCard() {
    // Semua stop (termasuk yang terakhir) sudah ditandai "Sudah
    // Sampai" -- lihat catatan di _markArrived. Dipakai buat ganti
    // tampilan kartu ini jadi status "selesai" alih-alih nunjukkin
    // leg/jarak yang sudah tidak ada lagi.
    final bool allArrived = _currentStopIndex >= widget.stops.length;

    final _RouteLeg? activeLeg =
        !allArrived && _currentStopIndex < _legs.length ? _legs[_currentStopIndex] : null;

    final double distanceKm = (activeLeg?.distanceMeters ?? 0) / 1000;
    final double durationMin = (activeLeg?.durationSeconds ?? 0) / 60;

    final RouteStop? activeStop = allArrived ? null : widget.stops[_currentStopIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TRAVEL MODE SWITCH -- "Jalan Kaki" dihapus, diganti
          // "Motor" & "Bus" (jadi Mobil/Motor/Bus). 3 tombol +
          // counter "Tujuan x/y" dipisah jadi 2 baris (bukan 1 baris
          // pakai Spacer seperti dulu) supaya tidak sesak di layar
          // sempit sekarang isinya nambah satu tombol.

          Row(
            children: [
              _buildModeButton(
                mode: _TravelMode.car,
                icon: Icons.directions_car,
                label: 'Mobil',
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                mode: _TravelMode.motorcycle,
                icon: Icons.two_wheeler,
                label: 'Motor',
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                mode: _TravelMode.bus,
                icon: Icons.directions_bus,
                label: 'Bus',
              ),
            ],
          ),

          if (widget.stops.length > 1) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tujuan ${allArrived ? widget.stops.length : _currentStopIndex + 1}/${widget.stops.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyText,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (!allArrived) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                Text(
                  durationMin < 60
                      ? '${durationMin.round()} menit'
                      : '${(durationMin / 60).toStringAsFixed(1)} jam',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Menuju ${activeStop!.name}',
              style: const TextStyle(fontSize: 12, color: AppColors.greyText),
            ),
          ] else ...[
            // Semua stop sudah ditandai "Sudah Sampai" -- ganti
            // baris jarak/durasi/"Menuju..." dengan status selesai.
            Row(
              children: const [
                Icon(Icons.check_circle, size: 20, color: AppColors.darkBlue),
                SizedBox(width: 8),
                Text(
                  'Semua destinasi sudah dikunjungi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlue,
                  ),
                ),
              ],
            ),
          ],

          // Tombol "Tandai Sudah Sampai" HANYA dirender kalau bukan
          // readOnly -- lihat komentar widget.readOnly di atas.
          // Sisa kartu info (mode kendaraan, jarak, durasi, "Menuju
          // ...") tetap sama persis supaya bentuk/isi kartunya identik
          // dengan versi navigasi aktif, cuma aksinya yang dihilangkan.
          if (!widget.readOnly) ...[
            const SizedBox(height: 16),

            // Sinkron ke TripScreen lewat widget.onStopIndexChanged
            // (dipanggil di _markArrived) -- lihat komentar di sana.
            //
            // CATATAN: sebelumnya kondisi tombol ini digabung dengan
            // 'widget.stops.length > 1' (dulu dipakai bareng counter
            // "Tujuan x/y" di atas) -- akibatnya kalau destinasi hari
            // itu cuma 1, tombol "Tandai Sudah Sampai" ikut hilang
            // total padahal user tetap butuh cara menandai dia sudah
            // sampai. Sekarang dipisah: counter tetap butuh > 1 stop,
            // tombol cukup butuh !readOnly.
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: allArrived ? null : _markArrived,
                style: ElevatedButton.styleFrom(
                  backgroundColor: allArrived ? const Color(0xFFEDEDED) : AppColors.darkBlue,
                  foregroundColor: allArrived ? AppColors.greyText : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
                child: Text(
                  allArrived
                      ? 'Semua Destinasi Sudah Dikunjungi'
                      : 'Tandai Sudah Sampai di ${activeStop!.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required _TravelMode mode,
    required IconData icon,
    required String label,
  }) {
    final bool active = _travelMode == mode;

    return GestureDetector(
      onTap: () => _changeTravelMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue :  AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : AppColors.greyText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}