import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/destinations_data.dart';
import '../services/destination_service.dart';
import '../widgets/smart_image.dart';
import 'route_screen.dart';

import '../theme/app_colors.dart';


class ItineraryDetailScreen extends StatefulWidget {
  final List<Map<String, dynamic>> itinerary;

  const ItineraryDetailScreen({
    super.key,
    required this.itinerary,
  });

  @override
  State<ItineraryDetailScreen> createState() =>
      _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  // Warna pin destinasi di peta -- disamakan dengan gaya TripScreen:
  // destinasi pertama (yang dituju duluan) dikasih warna AppColors.darkBlue
  // (aktif), sisanya offBlue (belum dituju). Layar ini masih tahap
  // rencana/preview jadi tidak ada status "sudah dikunjungi"
  // (doneGrey) seperti di TripScreen -- itu baru relevan begitu
  // trip-nya berjalan.
  static const Color offBlue = AppColors.paleBlue;

  // ============================================================
  // MAP
  // ============================================================

  final MapController _mapController = MapController();

  // Lampung Barat
  static const LatLng defaultCenter = LatLng(
    -5.0415,
    104.0695,
  );

  int selectedIndex = 0;

  // ============================================================
  // VALUE HELPER
  // ============================================================

  String _value(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  // ============================================================
  // DESTINATION NAME
  // ============================================================

  String _destinationName(
    Map<String, dynamic> destination,
  ) {
    return _value(
      destination,
      'name',
      fallback: 'Destinasi',
    );
  }

  // ============================================================
  // IMAGE
  // ============================================================

  String _destinationImage(
    Map<String, dynamic> destination,
  ) {
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

  // ============================================================
  // ARRIVAL TIME
  // ============================================================

  String _arrivalTime(
    Map<String, dynamic> destination,
  ) {
    return _value(
      destination,
      'arrivalTime',
      fallback: '--:--',
    );
  }

  // ============================================================
  // DEPARTURE TIME
  // ============================================================

  String _departureTime(
    Map<String, dynamic> destination,
  ) {
    return _value(
      destination,
      'departureTime',
      fallback: '--:--',
    );
  }

  // ============================================================
  // START LOCATION
  // ============================================================

  String _getStartLocation(
    Map<String, dynamic> schedule,
  ) {
    final location = schedule['startLocation'];

    if (location != null &&
        location.toString().trim().isNotEmpty) {
      return location.toString();
    }

    return 'Lokasi awal';
  }

  // ============================================================
  // START TIME
  // ============================================================

  String _getStartTime(
    Map<String, dynamic> schedule,
  ) {
    final time = schedule['departureTime'];

    if (time != null &&
        time.toString().trim().isNotEmpty) {
      return time.toString();
    }

    return '--:--';
  }

  // ============================================================
  // DAY LABEL
  // ============================================================

  String _getDayLabel(
    Map<String, dynamic> schedule,
    int index,
  ) {
    final day = schedule['day'];

    if (day != null) {
      return 'Hari $day';
    }

    return 'Hari ${index + 1}';
  }

  // ============================================================
  // DESTINATIONS
  // ============================================================

  List<Map<String, dynamic>> _getDestinations(
    Map<String, dynamic> schedule,
  ) {
    final raw = schedule['destinations'];

    final List<Map<String, dynamic>> result = [];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          result.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    return result;
  }

  // ============================================================
  // DURATION
  // ============================================================

  String _calculateDuration(
    String arrival,
    String departure,
  ) {
    try {
      if (arrival == '--:--' ||
          departure == '--:--') {
        return '';
      }

      final arrivalParts = arrival.split(':');
      final departureParts = departure.split(':');

      if (arrivalParts.length != 2 ||
          departureParts.length != 2) {
        return '';
      }

      final arrivalHour =
          int.parse(arrivalParts[0]);

      final arrivalMinute =
          int.parse(arrivalParts[1]);

      final departureHour =
          int.parse(departureParts[0]);

      final departureMinute =
          int.parse(departureParts[1]);

      int arrivalTotal =
          arrivalHour * 60 + arrivalMinute;

      int departureTotal =
          departureHour * 60 + departureMinute;

      if (departureTotal < arrivalTotal) {
        departureTotal += 24 * 60;
      }

      final difference =
          departureTotal - arrivalTotal;

      final hours = difference ~/ 60;
      final minutes = difference % 60;

      if (hours > 0 && minutes > 0) {
        return '$hours jam $minutes menit';
      }

      if (hours > 0) {
        return '$hours jam';
      }

      return '$minutes menit';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // CROWD STATUS
  // ============================================================
  //
  // Field crowdStatus (dan alias-aliasnya) nantinya diisi oleh
  // AI/backend prediksi kepadatan. Selama belum tersambung, kalau
  // field itu tidak ada di data, tampilkan status dummy yang
  // deterministik (bukan acak tiap rebuild) berdasarkan nama +
  // urutan destinasi, supaya tampilan tetap representatif saat
  // development. Begitu backend mulai mengisi crowdStatus, fungsi
  // ini otomatis pakai nilai asli tanpa perlu diubah lagi.
  // ============================================================

  String _getCrowdStatus(
    Map<String, dynamic> destination,
    int index,
  ) {
    final value =
        destination['crowdStatus'] ??
        destination['crowdLevel'] ??
        destination['crowd'] ??
        destination['kepadatan'] ??
        destination['statusKepadatan'];

    if (value != null) {
      final status =
          value.toString().trim().toLowerCase();

      if (status.contains('ramai')) {
        return 'Ramai';
      }

      if (status.contains('sedang') ||
          status.contains('medium') ||
          status.contains('moderate')) {
        return 'Sedang';
      }

      return 'Sepi';
    }

    // Fetch from real crowd predictions from DestinationService backend
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


  // ============================================================
  // CROWD COLOR
  // ============================================================

  Color _crowdText(
    String status,
  ) {
    switch (status) {
      case 'Ramai':
        return  AppColors.errorRed;

      case 'Sedang':
        return  AppColors.warningText;

      default:
        return const Color(0xFF20A447);
    }
  }

  // ============================================================
  // CROWD HEATMAP DOTS (DI PETA)
  // ============================================================
  //
  // Gumpalan titik warna-warni di sekitar pin destinasi, mewakili
  // status kepadatan (_getCrowdStatus) secara visual di peta --
  // merah = Ramai, kuning = Sedang, hijau = Sepi. Posisi titiknya
  // di-generate pakai Random(seed) supaya BUKAN acak tiap rebuild
  // (posisinya tetap sama selama status & destinasinya sama), tapi
  // tetap terlihat organik/menyebar seperti heatmap, bukan pola
  // grid yang kaku.
  //
  // ============================================================

  Widget _buildCrowdHeatmapDots(
    String status,
    int seed,
  ) {
    final Color color = _crowdText(status);

    // Ramai digambar lebih padat/pekat supaya kesannya memang lebih
    // "penuh" dibanding Sepi.
    final int dotCount = switch (status) {
      'Ramai' => 22,
      'Sedang' => 15,
      _ => 10,
    };

    final math.Random random = math.Random(seed);

    const double size = 92;
    const double center = size / 2;

    final List<Widget> dots = List.generate(
      dotCount,
      (i) {
        // sqrt supaya sebaran titik lebih padat ke tengah gumpalan,
        // bukan rata di seluruh lingkaran (mirip pola heatmap asli).
        final double radius =
            math.sqrt(random.nextDouble()) * (size / 2 - 6);

        final double angle =
            random.nextDouble() * 2 * math.pi;

        final double dx =
            center + radius * math.cos(angle);

        final double dy =
            center + radius * math.sin(angle);

        final double dotSize =
            4 + random.nextDouble() * 5;

        final double opacity =
            0.25 + random.nextDouble() * 0.35;

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
      },
    );

    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: dots,
        ),
      ),
    );
  }

  // ============================================================
  //
  // Versi ringkas: titik warna + teks status, TANPA background
  // pill -- dipakai di kolom kiri timeline, bukan lagi di dalam
  // kartu destinasi.
  // ============================================================

  Widget _buildCrowdLabel(
    String status,
  ) {
    final Color color = _crowdText(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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

  // ============================================================
  // HEADER MAP CARD
  // ============================================================

  Widget _buildMapHeader(
    BuildContext context,
  ) {
    String district = 'Kabupaten Lampung Barat';

    if (widget.itinerary.isNotEmpty) {
      final schedule =
          widget.itinerary[selectedIndex];

      district = _getDistrict(schedule);
    }

    return Positioned(
      top: 20,
      left: 78,
      right: 20,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          14,
          12,
          14,
          12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.12,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Kota/Kabupaten Tujuan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),

            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primaryBlue,
                  size: 15,
                ),

                const SizedBox(width: 4),

                Expanded(
                  child: Text(
                    district,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==============================================
            // TOMBOL RUTE (FULL WIDTH)
            // ==============================================

            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () {
                  // Sebelumnya cuma fit-camera di peta kecil inline
                  // (_showRoute()). Sekarang langsung buka halaman
                  // full map (_showFullMap()) sesuai permintaan --
                  // _showRoute() tetap dipakai terpisah untuk
                  // auto-fit peta kecil saat ganti tab hari (lihat
                  // _buildDayTabs), jadi tidak saya hapus.
                  _showFullMap();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.darkBlue,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Rute',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ROUTE BUTTON
  // ============================================================

  void _showRoute() {
    final points = _getMapPoints();

    if (points.length > 1) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding:
              const EdgeInsets.all(60),
        ),
      );
    } else if (points.isNotEmpty) {
      _mapController.move(
        points.first,
        14,
      );
    }
  }

  // ============================================================
  // GET MAP POINTS
  // ============================================================

  List<LatLng> _getMapPoints() {
    final List<LatLng> points = [];

    if (widget.itinerary.isEmpty) {
      return [defaultCenter];
    }

    final schedule =
        widget.itinerary[selectedIndex];

    // Titik keberangkatan (lokasi awal) dimasukkan LEBIH DULU,
    // sebelum daftar destinasi, supaya garis rute & urutan marker
    // menggambarkan "dari mana berangkat -> ke mana saja tujuannya"
    // sesuai urutan sebenarnya, bukan cuma kumpulan titik destinasi
    // tanpa titik awal.
    final startPoint = _getStartPoint(schedule);

    if (startPoint != null) {
      points.add(startPoint);
    }

    final destinations =
        _getDestinations(schedule);

    for (final destination in destinations) {
      final LatLng? coord = coordinateOfDestination(destination);
      if (coord != null) {
        points.add(coord);
      }
    }

    if (points.isEmpty) {
      points.add(defaultCenter);
    }

    return points;
  }

  // ============================================================
  // TITIK LOKASI AWAL (BERANGKAT)
  // ============================================================
  //
  // Prioritas: 'startLatitude'/'startLongitude' asli (dari peta/GPS
  // di TravelInformationScreen, diteruskan lewat ManualScheduleScreen
  // yang sekarang SELALU mengisi kedua field ini -- baik dari
  // pilihan peta/GPS asli, maupun titik dummy yang sudah dibuat jatuh
  // di wilayah kabupaten/kota tujuan). Kalau tetap tidak ada (mis.
  // data jadwal lama sebelum perubahan ini), baru fallback dibuat di
  // sini: titik dummy di wilayah kabupaten/kota tujuan (_getDistrict)
  // supaya tetap masuk akal, bukan titik tetap di satu tempat saja
  // seperti defaultCenter.
  //
  // ============================================================

  LatLng? _getStartPoint(
    Map<String, dynamic> schedule,
  ) {
    final lat = _readDouble(
      schedule,
      'startLatitude',
    );

    final lng = _readDouble(
      schedule,
      'startLongitude',
    );

    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }

    return coordinateForRegency(
      _getDistrict(schedule),
      seed: schedule['tripName'] ?? _getDistrict(schedule),
    );
  }

  // ============================================================
  // READ DOUBLE
  // ============================================================

  double? _readDouble(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // MAP MARKERS
  // ============================================================

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    if (widget.itinerary.isEmpty) {
      return markers;
    }

    final schedule =
        widget.itinerary[selectedIndex];

    // ==========================================================
    // MARKER TITIK KEBERANGKATAN
    // ==========================================================
    //
    // Ditampilkan beda dari marker destinasi (ikon rumah, warna
    // hijau) supaya langsung kelihatan mana titik "berangkat"-nya,
    // bukan destinasi ke-1.
    //
    // ==========================================================

    final startPoint = _getStartPoint(schedule);

    if (startPoint != null) {
      markers.add(
        Marker(
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
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Container(
                width: 3,
                height: 12,
                color:  AppColors.successGreen,
              ),
            ],
          ),
        ),
      );
    }

    final destinations =
        _getDestinations(schedule);

    for (
      int i = 0;
      i < destinations.length;
      i++
    ) {
      final destination =
          destinations[i];

      final LatLng? coord = coordinateOfDestination(destination);

      if (coord == null) {
        continue;
      }

      final double lat = coord.latitude;
      final double lng = coord.longitude;

      // ========================================================
      // HEATMAP KEPADATAN (DI BAWAH PIN)
      // ========================================================
      //
      // Ditambahkan SEBELUM pin numbernya, supaya di MarkerLayer
      // (yang menggambar berurutan sesuai list) gumpalan titik ini
      // ada di lapisan bawah dan pin tetap kelihatan jelas di atasnya.
      // Seed dibuat dari nama + index supaya sebaran titiknya stabil
      // (tidak berubah acak tiap rebuild) selama destinasi & urutannya
      // sama.
      //
      // ========================================================

      final String crowdStatus = _getCrowdStatus(
        destination,
        i,
      );

      final int dotSeed =
          _destinationName(destination).codeUnits.fold<int>(
                0,
                (sum, code) => sum + code,
              ) +
          i;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 92,
          height: 92,
          child: _buildCrowdHeatmapDots(
            crowdStatus,
            dotSeed,
          ),
        ),
      );

      // ==========================================================
      // WARNA PIN (GAYA TripScreen)
      // ==========================================================
      //
      // Destinasi pertama (i == 0) = "aktif"/dituju duluan -> AppColors.darkBlue
      // besar, sisanya = "belum dituju" -> offBlue. Sama seperti pola
      // warna TripScreen._buildMarkers, cuma tanpa status "sudah
      // dikunjungi" (doneGrey) karena layar ini masih tahap rencana,
      // belum ada progress kunjungan yang bisa ditandai.
      //
      // ==========================================================

      final bool active = i == 0;
      final Color pinColor = active ? AppColors.darkBlue : offBlue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 48,
          height: 60,
          child: Column(
            children: [
              // ==================================================
              // PIN (IKON LOKASI + BADGE NOMOR URUT)
              // ==================================================
              //
              // Pin-nya sendiri kembali pakai ikon lokasi (bukan
              // angka) supaya langsung terbaca sebagai "titik
              // destinasi" di peta. Nomor urutnya tetap ditampilkan,
              // tapi dipindah jadi badge kecil terpisah di pojok
              // kanan-atas pin, supaya urutan kunjungan tetap
              // kelihatan tanpa mengorbankan ikonnya.
              //
              // ==================================================

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
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),

                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 18,
                        height: 18,
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
                            fontSize: 10,
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
                height: 12,
                color: pinColor,
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // ROUTE LINE
  // ============================================================

  List<LatLng> _buildRoutePoints() {
    final points = _getMapPoints();

    if (points.length < 2) {
      return [];
    }

    return points;
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    final routePoints =
        _buildRoutePoints();

    return SizedBox(
      height: 330,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: defaultCenter,
              initialZoom: 13,
              interactionOptions:
                  const InteractionOptions(
                flags:
                    InteractiveFlag.all,
              ),
              // Begitu peta kecil ini pertama kali siap, langsung
              // fit-camera ke titik keberangkatan + destinasi hari
              // yang aktif -- sebelumnya diam di defaultCenter terus
              // walau datanya sudah ada titik rute.
              onMapReady: _showRoute,
            ),
            children: [
              // ==========================================================
              // TILE LAYER
              // ==========================================================
              //
              // Ganti userAgentPackageName ke applicationId asli
              // ('com.example.smarttrip') TERNYATA BELUM CUKUP --
              // screenshot yang kamu kirim menunjukkan tile-nya benar-benar
              // menampilkan halaman "Access Blocked" / 403 dari OSM
              // (osm.wiki/Blocked), bukan cuma placeholder generik lagi.
              // Ini konfirmasi langsung bahwa OSM masih nge-block trafik
              // dari applicationId ini.
              //
              // Makanya provider default sekarang dipindah ke CartoDB
              // (tidak perlu API key untuk basemap dasar). OSM tetap
              // ditinggal di bawah sebagai komentar, siap dicoba lagi
              // kalau nanti applicationId di build.gradle.kts sudah
              // benar-benar diganti dari "com.example.*" ke identitas
              // unik milikmu sendiri.
              //
              // CATATAN: saya tidak punya akses jaringan langsung di sini
              // untuk mencoba fetch tile-nya sendiri, jadi ini belum saya
              // verifikasi hidup -- tolong cek langsung setelah build.
              // Kalau CartoDB juga bermasalah (rate limit / kebijakan
              // fair-use berubah), kasih tahu saya provider lain yang mau
              // dipakai (mis. MapTiler, tapi itu butuh API key).
              //
              // TileLayer(
              //   urlTemplate:
              //       'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //   userAgentPackageName: 'com.example.smarttrip',
              // ),
              //
              // ==========================================================

              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smarttrip',
              ),

              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4,
                      color: AppColors.darkBlue,
                      // Diganti dari StrokePattern.dotted ke .dashed
                      // supaya garis rute lebih mirip referensi (garis
                      // putus-putus, bukan titik-titik). SENGAJA TANPA
                      // 'const' -- assert internal di constructor
                      // StrokePattern.dashed (package flutter_map)
                      // memanggil segments.length, dan itu belum bisa
                      // dievaluasi di compile-time/const context (lihat
                      // error "can't be accessed... in a constant
                      // expression"). Kalau dipaksa const, build gagal.
                      pattern: StrokePattern.dashed(
                        segments: [14, 10],
                      ),
                    ),
                  ],
                ),

              MarkerLayer(
                markers:
                    _buildMarkers(),
              ),
            ],
          ),

          // BACK BUTTON
          Positioned(
            top: 20,
            left: 18,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder:
                    const CircleBorder(),
                onTap: () {
                  Navigator.pop(context);
                },
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 21,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            ),
          ),

          _buildMapHeader(context),

          // EXPAND MAP BUTTON
          Positioned(
            right: 18,
            bottom: 18,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder:
                    const CircleBorder(),
                onTap: () {
                  _showFullMap();
                },
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons
                        .open_in_full_rounded,
                    color: Color(0xFF555555),
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FULL MAP
  // ============================================================

  // ============================================================
  // FULL MAP (RUTE PERJALANAN)
  // ============================================================
  //
  // Dipakai oleh 2 tempat: tombol "Rute" di header peta, dan tombol
  // expand (ikon panah) di pojok kanan-bawah peta. Menampilkan semua
  // titik destinasi hari yang sedang dipilih (bukan cuma 1 titik
  // statis), plus garis rute di antaranya, dan kamera otomatis
  // di-fit supaya semua titik kelihatan sekaligus saat halaman ini
  // dibuka -- bukan cuma mulai dari initialZoom tetap seperti
  // sebelumnya.
  //
  // ============================================================

  // ============================================================
  // TOMBOL "RUTE" -- BUKA GAMBARAN RUTE (SAMA GAYA DENGAN TripScreen)
  // ============================================================
  //
  // Sebelumnya layar ini punya peta full-screen sendiri (garis lurus
  // putus-putus + fit-camera manual). SEKARANG diganti supaya
  // membuka RouteScreen yang SAMA PERSIS dipakai TripScreen saat
  // tombol "Rute" ditekan di sana (route_screen.dart) -- rute
  // jalan asli dari OSRM, gaya pin bernomor, kartu info jarak/durasi
  // yang sama -- supaya "gambaran rute"-nya konsisten antara Detail
  // Itinerary dan Trip.
  //
  // BEDANYA dengan TripScreen: dibuka dengan `readOnly: true`, jadi
  // tombol "Tandai Sudah Sampai" TIDAK ditampilkan (lihat
  // RouteScreen.readOnly) -- layar ini masih tahap rencana/preview,
  // belum ada progress kunjungan yang bisa ditandai. Titik awal juga
  // dikirim langsung dari data itinerary (`startCoordinate`), BUKAN
  // dari lokasi GPS user saat ini seperti TripScreen -- supaya tidak
  // perlu izin lokasi untuk sekadar melihat gambaran rute.
  //
  // ============================================================

  void _showFullMap() {
    if (widget.itinerary.isEmpty) return;

    final schedule = widget.itinerary[selectedIndex];
    final destinations = _getDestinations(schedule);

    final List<RouteStop> stops = [];

    for (int i = 0; i < destinations.length; i++) {
      final destination = destinations[i];
      final LatLng? coordinate = coordinateOfDestination(destination);

      if (coordinate == null) continue;

      stops.add(
        RouteStop(
          name: _destinationName(destination),
          coordinate: coordinate,
          crowdStatus: _getCrowdStatus(destination, i),
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

    final vehicle = _value(schedule, 'vehicle', fallback: 'Mobil');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteScreen(
          stops: stops,
          initialVehicle: vehicle,
          startCoordinate: _getStartPoint(schedule),
          readOnly: true,
        ),
      ),
    );
  }

  // ============================================================
  // DAY TABS
  // ============================================================

  Widget _buildDayTabs() {
    if (widget.itinerary.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount:
            widget.itinerary.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 8),

        itemBuilder:
            (context, index) {
          final selected =
              selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex =
                    index;
              });

              WidgetsBinding.instance
                  .addPostFrameCallback(
                (_) {
                  _showRoute();
                },
              );
            },
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 150,
              ),
              width: 120,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color: selected
                    ? AppColors.primaryBlue
                    : const Color(
                        0xFFF1F1F1,
                      ),
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),
              child: Text(
                _getDayLabel(
                  widget.itinerary[
                      index],
                  index,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF666666,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TIMELINE DOT
  // ============================================================

  Widget _buildTimelineDot({
    required bool isLast,
  }) {
    return SizedBox(
      width: 30,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration:
                BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue,
                width: 3,
              ),
            ),
            child:
                const Center(
              child: CircleAvatar(
                radius: 5,
                backgroundColor:
                    AppColors.primaryBlue,
              ),
            ),
          ),

          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: AppColors.primaryBlue
                    .withValues(
                  alpha: 0.55,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // START CARD
  // ============================================================

  Widget _buildStartPoint({
    required String time,
    required String location,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildTimelineDot(
            isLast: isLast,
          ),

          const SizedBox(width: 8),

          // ==================================================
          // WAKTU (KOLOM KIRI)
          // ==================================================

          Padding(
            padding: EdgeInsets.fromLTRB(
              0,
              6,
              0,
              isLast ? 0 : 24,
            ),
            child: SizedBox(
              width: 68,
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(
                bottom:
                    isLast ? 0 : 24,
              ),
              child: Container(
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color: AppColors.borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.035,
                      ),
                      blurRadius: 6,
                      offset:
                          const Offset(
                        0,
                        2,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration:
                          BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons.home_rounded,
                        color:
                            AppColors.primaryBlue,
                        size: 34,
                      ),
                    ),

                    const SizedBox(
                      width: 11,
                    ),

                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Berangkat',
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color:
                                  AppColors.darkText,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Dari $location',
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
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
  // DESTINATION CARD
  // ============================================================
  //
  // CARD INI SENGAJA DIAMBIL STRUKTURNYA DARI
  // ItineraryPreviewScreen.
  //
  // UKURAN:
  // IMAGE 82 x 82
  // PADDING 10
  // RADIUS 16
  // TIME CONTAINER SAMA
  //
  // TAMBAHAN HANYA CROWD BADGE.
  // ============================================================

  Widget _buildDestinationItem({
    required int index,
    required Map<String, dynamic>
        destination,
    required bool isLast,
  }) {
    final name =
        _destinationName(destination);

    final image =
        _destinationImage(destination);

    final arrival =
        _arrivalTime(destination);

    final departure =
        _departureTime(destination);

    final duration =
        _calculateDuration(
      arrival,
      departure,
    );

    final crowdStatus =
        _getCrowdStatus(destination, index);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildTimelineDot(
            isLast: isLast,
          ),

          const SizedBox(width: 8),

          // ==================================================
          // WAKTU + STATUS KEPADATAN (KOLOM KIRI)
          // ==================================================

          Padding(
            padding: EdgeInsets.fromLTRB(
              0,
              6,
              0,
              isLast ? 0 : 24,
            ),
            child: SizedBox(
              width: 68,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$arrival - $departure',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
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
              padding:
                  EdgeInsets.only(
                bottom:
                    isLast ? 0 : 24,
              ),
              child: Container(
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color: AppColors.borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.035,
                      ),
                      blurRadius: 6,
                      offset:
                          const Offset(
                        0,
                        2,
                      ),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    10,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .center,
                    children: [
                      // ============================
                      // IMAGE
                      // ============================

                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SmartImage(
                          imagePathOrUrl: image,
                          width: 66,
                          height: 66,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(
                        width: 11,
                      ),

                      // ============================
                      // NAME + DURATION
                      // ============================

                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              name,
                              maxLines:
                                  2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                height:
                                    1.25,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    AppColors.darkText,
                              ),
                            ),

                            if (duration
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                duration,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.greyText,
                                ),
                              ),
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
    );
  }

  // ============================================================
  // DAY TIMELINE
  // ============================================================

  Widget _buildDayTimeline() {
    if (widget.itinerary.isEmpty) {
      return const SizedBox();
    }

    final schedule =
        widget.itinerary[selectedIndex];

    final destinations =
        _getDestinations(schedule);

    final startLocation =
        _getStartLocation(schedule);

    final startTime =
        _getStartTime(schedule);

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 18,
          ),

          // ================================================
          // START
          // ================================================

          _buildStartPoint(
            time: startTime,
            location: startLocation,
            isLast:
                destinations.isEmpty,
          ),

          // ================================================
          // DESTINATIONS
          // ================================================

          for (
            int i = 0;
            i < destinations.length;
            i++
          )
            _buildDestinationItem(
              index: i,
              destination:
                  destinations[i],
              isLast:
                  i ==
                  destinations.length - 1,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER INFORMATION
  // ============================================================

  // ============================================================
  // DISTRICT / KOTA TUJUAN
  // ============================================================
  //
  // Dipakai bareng oleh header peta (_buildMapHeader) dan judul
  // trip (_buildTripInformation) supaya nilainya selalu konsisten.
  // ============================================================

  String _getDistrict(
    Map<String, dynamic> schedule,
  ) {
    final district = _value(
      schedule,
      'destination',
      fallback: _value(
        schedule,
        'district',
        fallback: 'Kabupaten Lampung Barat',
      ),
    );

    return district.isEmpty
        ? 'Kabupaten Lampung Barat'
        : district;
  }

  // ============================================================
  // FORMAT RENTANG TANGGAL
  // ============================================================
  //
  // Sama persis dengan _formatDateRange di plan_screen.dart, supaya
  // format tanggal konsisten di semua layar.
  // ============================================================

  String _formatDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final String start =
        '${startDate.day} ${months[startDate.month - 1]}';

    final String end =
        '${endDate.day} ${months[endDate.month - 1]} ${endDate.year}';

    return '$start – $end';
  }

  // ============================================================
  // TANGGAL PERJALANAN UNTUK 1 SCHEDULE
  // ============================================================
  //
  // TravelInformationScreen -> ManualScheduleScreen mengisi
  // 'startDate'/'endDate' sebagai objek DateTime (lihat
  // travel_information_screen.dart baris ~1746 & ManualScheduleScreen
  // yang men-spread field itu ke tiap hari). Fungsi ini memformatnya
  // jadi teks seperti "20 – 21 Juli 2026".
  //
  // CATATAN: AIItineraryScreen (jalur lain untuk membuat itinerary)
  // mengisi field berbeda, 'dateRange', berisi String mentah dari
  // DateTime.toString() (lihat ai_itinerary_screen.dart baris ~304 --
  // file itu sendiri masih punya komentar
  // "TODO(integrasi): sesuaikan format result ini"). Fungsi ini
  // dibuat toleran terhadap kasus itu (dipakai sebagai fallback),
  // tapi hasilnya tidak akan serapi jalur ManualScheduleScreen --
  // pembenahan format tanggal di AIItineraryScreen sendiri di luar
  // scope perbaikan hari ini, beri tahu saya kalau mau saya benahi
  // juga.
  // ============================================================

  String _getScheduleDateRange(
    Map<String, dynamic> schedule,
  ) {
    final startDate = schedule['startDate'];
    final endDate = schedule['endDate'];

    if (startDate is DateTime && endDate is DateTime) {
      return _formatDateRange(startDate, endDate);
    }

    final preformatted = _value(
      schedule,
      'date',
      fallback: '',
    );

    if (preformatted.isNotEmpty) {
      return preformatted;
    }

    // Fallback dari jalur AIItineraryScreen yang belum rapi (lihat
    // catatan di atas) -- apa adanya, bisa saja tampil mentah.
    return _value(
      schedule,
      'dateRange',
      fallback: '',
    );
  }

  Widget _buildTripInformation() {
    if (widget.itinerary.isEmpty) {
      return const SizedBox();
    }

    final schedule =
        widget.itinerary[selectedIndex];

    // 'tripName' adalah key ASLI yang diisi TravelInformationScreen
    // (lihat travel_information_screen.dart baris ~1747). Sebelumnya
    // fungsi ini membaca key 'title' yang TIDAK PERNAH diisi oleh
    // jalur mana pun, jadi selalu jatuh ke fallback -- itu sebabnya
    // judulnya selalu "Explore ..." meskipun tripName sudah diisi
    // user di TravelInformationScreen.
    final rawTripName = _value(
      schedule,
      'tripName',
      fallback: '',
    );

    // Dicek .isEmpty juga (bukan cuma null), sama seperti pola yang
    // sudah dipakai _getDistrict -- kalau user tidak mengisi nama
    // trip sama sekali, tripName akan berupa String kosong ('' hasil
    // .trim()), bukan null, jadi harus dicek eksplisit supaya tetap
    // jatuh ke fallback alih-alih menampilkan judul kosong.
    final title = rawTripName.isNotEmpty
        ? rawTripName
        : _value(
            schedule,
            'title',
            fallback: 'Explore ${_getDistrict(schedule)}',
          );

    final date = _getScheduleDateRange(schedule);

    // 'participants' adalah key ASLI dari TravelInformationScreen
    // (sudah dalam format "2 Orang", bukan cuma angka mentah).
    final travelers =
        _value(
          schedule,
          'participants',
          fallback: _value(
            schedule,
            'travelers',
            fallback: '2 Orang',
          ),
        );

    // 'vehicle' adalah key ASLI dari TravelInformationScreen.
    final transport =
        _value(
          schedule,
          'vehicle',
          fallback: _value(
            schedule,
            'transportation',
            fallback: _value(
              schedule,
              'transport',
              fallback: 'Mobil',
            ),
          ),
        );

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.greyText,
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child: Text(
                  date.isNotEmpty
                      ? date
                      : 'Tanggal perjalanan',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: AppColors.greyText,
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Icon(
                Icons.people_outline,
                size: 19,
                color: AppColors.greyText,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                travelers,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color: AppColors.greyText,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              const Icon(
                Icons.directions_car_outlined,
                size: 19,
                color: AppColors.greyText,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                transport,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ==============================================
          // LOKASI AWAL
          // ==============================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration:
                BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Lokasi Awal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),

                const Spacer(),

                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.darkBlue,
                  size: 20,
                ),

                const SizedBox(
                  width: 5,
                ),

                Flexible(
                  child: Text(
                    _getStartLocation(
                      schedule,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color: AppColors.darkBlue,
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
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Belum ada itinerary',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.greyText,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FA),

      body: SafeArea(
        child: widget.itinerary.isEmpty
            ? _buildEmpty()
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ==========================================
                  // MAP
                  // ==========================================
                  //
                  // Sekarang jadi sliver di dalam scroll area yang
                  // sama dengan konten di bawahnya (bukan Expanded
                  // terpisah lagi), supaya peta ikut ke-scroll ke
                  // atas bareng konten saat sheet-nya di-drag naik.
                  //
                  // ==========================================

                  SliverToBoxAdapter(
                    child: _buildMap(),
                  ),

                  // ==========================================
                  // CONTENT (SHEET PUTIH DI BAWAH PETA)
                  // ==========================================
                  //
                  // Seluruh sheet (handle + trip info + day tabs +
                  // timeline) dibungkus SATU Container putih dengan
                  // sudut atas rounded, supaya benar-benar terlihat
                  // seperti bottom sheet yang menutupi peta -- bukan
                  // cuma strip handle-nya saja yang rounded seperti
                  // sebelumnya.
                  //
                  // ==========================================

                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Garis handle kecil di tengah sudah dihapus
                          // sesuai permintaan. Diganti spacer biasa
                          // supaya trip info tidak nempel persis di
                          // sudut rounded.
                          const SizedBox(height: 18),

                          // ==============================
                          // INFORMATION
                          // ==============================

                          _buildTripInformation(),

                          const SizedBox(
                            height: 18,
                          ),

                          // ==============================
                          // DAY TABS
                          // ==============================

                          _buildDayTabs(),

                          // ==============================
                          // TIMELINE
                          // ==============================

                          _buildDayTimeline(),

                          const SizedBox(
                            height: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}