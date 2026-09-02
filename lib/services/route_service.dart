import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'api_service.dart';

// ================================================================
// ROUTE SERVICE -- SUMBER TUNGGAL PERHITUNGAN RUTE JALAN ASLI
// ================================================================
//
// LATAR BELAKANG (kenapa file ini dibuat):
// Sebelumnya ada DUA cara berbeda untuk "berapa lama dari titik A ke
// titik B" di aplikasi ini:
// 1. RouteScreen (peta preview rute)   -> rute jalan ASLI dari
//    backend proxy 'route/directions' / OSRM (router.project-osrm.org).
// 2. ManualScheduleScreen (jam otomatis) -> estimateTravelTime() di
//    destinations_data.dart, rumus GARIS LURUS (haversine x 1.3 faktor
//    kelokan / kecepatan rata-rata kendaraan).
//
// Karena dua rumus itu berbeda dari akarnya, jam tiba yang dihitung
// otomatis di Manual Schedule TIDAK PERNAH sinkron dengan durasi yang
// tampil di peta rute (RouteScreen). fetchRealRoute() di file ini
// jadi SATU-SATUNYA sumber untuk keduanya -- ManualScheduleScreen
// sekarang memanggil fungsi yang sama persis (backend proxy -> OSRM
// -> fallback garis lurus) yang dipakai RouteScreen, supaya angkanya
// benar-benar sama.
//
// KONSEKUENSI: fungsi ini butuh internet (fetch ke backend/OSRM),
// jadi dipanggil secara ASYNC. Layar pemanggil WAJIB menampilkan
// indikator loading selagi menunggu (lihat isCalculatingByDay di
// ManualScheduleScreen) supaya user tahu jam tiba belum final.
//
// FALLBACK kalau backend & OSRM dua-duanya gagal/timeout/offline:
// tetap pakai estimasi garis lurus (rumus lama) SUPAYA:
// 1. Layar tidak macet/error total kalau tidak ada internet.
// 2. Fallback ini sama persis dengan fallback yang dipakai
//    RouteScreen (lihat _RouteScreenState._loadAllLegs), jadi walau
//    lagi fallback pun angka di kedua layar tetap konsisten.
// ================================================================

class RouteResult {
  final double distanceMeters;
  final Duration duration;

  // true kalau hasil ini dari estimasi garis lurus (fallback),
  // bukan rute jalan asli -- dipakai kalau layar pemanggil mau kasih
  // tahu user bahwa angka ini masih perkiraan (opsional, tidak wajib
  // dipakai).
  final bool isEstimate;

  const RouteResult({
    required this.distanceMeters,
    required this.duration,
    this.isEstimate = false,
  });
}

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

double _haversineMeters(LatLng a, LatLng b) {
  const double earthRadiusM = 6371000;

  double toRad(double degree) => degree * (math.pi / 180);

  final double dLat = toRad(b.latitude - a.latitude);
  final double dLon = toRad(b.longitude - a.longitude);

  final double lat1 = toRad(a.latitude);
  final double lat2 = toRad(b.latitude);

  final double h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));

  return earthRadiusM * c;
}

// Fallback garis lurus -- SENGAJA disalin (bukan memanggil balik ke
// estimateTravelTime di destinations_data.dart) supaya route_service
// tidak perlu impor balik ke sana. Rumusnya harus tetap SAMA PERSIS
// dengan estimateTravelTime kalau nanti ada yang mengubah salah
// satunya, tolong ubah dua-duanya.
RouteResult _fallbackEstimate(LatLng from, LatLng to, {String? vehicle}) {
  final double distanceMeters = _haversineMeters(from, to);

  const double roadWindingFactor = 1.3;

  final double speedKmh = _averageSpeedKmhFor(vehicle);

  final double distanceKm = (distanceMeters / 1000) * roadWindingFactor;

  final double hours = distanceKm / speedKmh;

  final int minutes = (hours * 60).round().clamp(5, 24 * 60);

  return RouteResult(
    distanceMeters: distanceMeters,
    duration: Duration(minutes: minutes),
    isEstimate: true,
  );
}

// Mode OSRM/backend -- dicocokkan dengan 'contains' (bukan '=='
// persis), SAMA PERSIS dengan _resolveInitialTravelMode di
// RouteScreen, supaya profil kendaraan yang dipilih di sini konsisten
// dengan yang dipakai peta rute.
String _routeModeFor(String? vehicle) {
  final String normalized = (vehicle ?? '').trim().toLowerCase();

  if (normalized.contains('motor')) return 'motorcycle';
  if (normalized.contains('bus')) return 'bus';

  return 'car';
}

// ================================================================
// AMBIL RUTE ASLI (JARAK + DURASI) DARI SATU TITIK KE TITIK LAIN
// ================================================================
//
// Urutan sumber SAMA PERSIS dengan RouteScreen._fetchLeg:
// 1. Backend routing proxy ('route/directions') -- ORS_API_KEY aman
//    di backend .env.
// 2. Fallback ke OSRM demo server langsung dari Flutter kalau backend
//    gagal/offline.
// 3. Fallback terakhir: estimasi garis lurus (_fallbackEstimate)
//    kalau OSRM juga gagal/timeout -- request TIDAK PERNAH melempar
//    error ke pemanggil, supaya layar (mis. jam otomatis di Manual
//    Schedule) tidak macet walau tidak ada internet sama sekali.
//
// Tidak minta geometry rute (overview=false / tidak mengirim
// 'points') karena pemanggil di sini cuma butuh jarak & durasi, bukan
// garis rute untuk digambar -- lebih ringan & cepat dibanding yang
// dipakai RouteScreen.
// ================================================================

Future<RouteResult> fetchRealRoute(
  LatLng origin,
  LatLng destination, {
  String? vehicle,
}) async {
  final String modeParam = _routeModeFor(vehicle);

  final String originStr = '${origin.longitude},${origin.latitude}';
  final String destStr = '${destination.longitude},${destination.latitude}';

  // --------------------------------------------------------
  // 1. BACKEND ROUTE PROXY
  // --------------------------------------------------------
  try {
    final responseData = await ApiService.instance.get(
      'route/directions',
      queryParams: {
        'origin': originStr,
        'destination': destStr,
        'mode': modeParam,
      },
    ).timeout(const Duration(seconds: 12));

    if (responseData != null && responseData is Map<String, dynamic>) {
      if (responseData['status'] == 'success' &&
          responseData['distance'] != null &&
          responseData['duration'] != null) {
        return RouteResult(
          distanceMeters: (responseData['distance'] as num).toDouble(),
          duration: Duration(
            seconds: (responseData['duration'] as num).round(),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('⚠️ [ROUTE SERVICE] Backend routing proxy gagal, fallback ke OSRM: $e');
  }

  // --------------------------------------------------------
  // 2. FALLBACK KE OSRM LANGSUNG
  // --------------------------------------------------------
  try {
    const profile = 'driving';
    final coordinates = '$originStr;$destStr';

    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/$coordinates'
      '?overview=false',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['code'] == 'Ok' &&
          data['routes'] != null &&
          (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];

        return RouteResult(
          distanceMeters: (route['distance'] as num).toDouble(),
          duration: Duration(seconds: (route['duration'] as num).round()),
        );
      }
    }
  } catch (e) {
    debugPrint('⚠️ [ROUTE SERVICE] OSRM fallback gagal, pakai estimasi garis lurus: $e');
  }

  // --------------------------------------------------------
  // 3. FALLBACK TERAKHIR: ESTIMASI GARIS LURUS
  // --------------------------------------------------------
  return _fallbackEstimate(origin, destination, vehicle: vehicle);
}