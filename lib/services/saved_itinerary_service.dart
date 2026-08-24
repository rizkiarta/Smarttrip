import 'package:flutter/material.dart';

// ================================================================
// SAVED ITINERARY SERVICE
// ================================================================
//
// Sumber kebenaran tunggal (single source of truth) untuk SEMUA
// itinerary yang tersimpan (bisa lebih dari satu dalam satu sesi).
// Dipakai bersama oleh PlanScreen dan ItineraryPreviewScreen (dan
// layar lain yang butuh) supaya data selalu sinkron, TANPA
// bergantung pada rantai Navigator.pop(result) yang gampang putus
// kalau ada popUntil/pushReplacement di tengah jalan.
//
// Ini murni state in-memory di sisi Flutter (ValueNotifier bawaan),
// sama polanya dengan SavedDestinationsService di destinations_data.dart.
// Belum menyentuh backend apa pun -- nanti kalau backend sudah siap,
// tinggal isi method save/remove ini yang diganti jadi panggilan API,
// pemanggil (PlanScreen, ItineraryPreviewScreen, dst) tidak perlu
// diubah karena tanda tangan/API service ini tetap sama.
//
// ================================================================

class SavedItineraryService {
  SavedItineraryService._internal();

  static final SavedItineraryService instance =
      SavedItineraryService._internal();

  // ============================================================
  // SEMUA ITINERARY YANG TERSIMPAN
  // ============================================================
  //
  // Setiap elemen list luar = satu itinerary (hasil satu kali
  // "Simpan Jadwal"), berisi List per hari seperti sebelumnya:
  // day, tripName, startDate, endDate, participants, vehicle,
  // destination, startLocation, departureTime, destinations: [...],
  // plus 'itineraryId' yang ditempelkan otomatis di save() supaya
  // tiap itinerary bisa dibedakan (dipakai untuk update/hapus yang
  // tepat, bukan cuma yang pertama/terakhir).
  //
  // ============================================================

  final ValueNotifier<List<List<Map<String, dynamic>>>> itineraries =
      ValueNotifier<List<List<Map<String, dynamic>>>>([]);

  bool get hasItinerary => itineraries.value.isNotEmpty;

  // ============================================================
  // AMBIL ID ITINERARY (DARI HARI PERTAMANYA)
  // ============================================================

  String? _idOf(List<Map<String, dynamic>> dailySchedules) {
    if (dailySchedules.isEmpty) {
      return null;
    }

    return dailySchedules.first['itineraryId']?.toString();
  }

  // Versi publik dari _idOf -- dipakai pemanggil luar (TripScreen,
  // HistoryScreen, dst) yang butuh itineraryId tapi tidak boleh akses
  // method private di atas.
  String? itineraryIdOf(List<Map<String, dynamic>> dailySchedules) {
    return _idOf(dailySchedules);
  }

  // Cocokkan nomor hari (field 'day', bisa int atau String) dengan
  // [dayNumber] yang dicari -- helper kecil dipakai di beberapa method
  // status di bawah supaya parsing-nya konsisten.
  bool _isDayNumber(Map<String, dynamic> schedule, int dayNumber) {
    final dynamic day = schedule['day'];
    final int? parsed = day is int ? day : int.tryParse(day?.toString() ?? '');
    return parsed == dayNumber;
  }

  // ============================================================
  // SIMPAN ITINERARY
  // ============================================================
  //
  // - Kalau dailySchedules BELUM punya 'itineraryId' (itinerary
  //   baru dari alur TravelInformationScreen -> ... -> Preview),
  //   dibuatkan id baru lalu DITAMBAHKAN sebagai itinerary baru --
  //   itinerary yang sudah ada sebelumnya TIDAK ikut hilang/tertimpa
  //   lagi seperti versi lama.
  // - Kalau SUDAH punya 'itineraryId' dan id itu masih ada di daftar
  //   (alur edit lewat PlanScreen -> _editItinerary), itinerary lama
  //   dengan id yang sama DIGANTI (update in-place), bukan
  //   ditambahkan sebagai duplikat baru.
  //
  // ============================================================

  void save(List<Map<String, dynamic>> dailySchedules) {
    final List<Map<String, dynamic>> copy = List<Map<String, dynamic>>.from(
      dailySchedules.map((day) => Map<String, dynamic>.from(day)),
    );

    final String? existingId = _idOf(copy);

    final List<List<Map<String, dynamic>>> current =
        List<List<Map<String, dynamic>>>.from(itineraries.value);

    final int existingIndex = existingId != null
        ? current.indexWhere((saved) => _idOf(saved) == existingId)
        : -1;

    // Kalau belum punya id, atau id-nya sudah tidak ditemukan lagi
    // (mis. itinerary aslinya sudah dihapus di tengah proses edit),
    // buatkan id baru supaya tidak salah menimpa itinerary lain.
    final String itineraryId = (existingIndex != -1 && existingId != null)
        ? existingId
        : DateTime.now().millisecondsSinceEpoch.toString();

    for (final day in copy) {
      day['itineraryId'] = itineraryId;
    }

    if (existingIndex != -1) {
      current[existingIndex] = copy;
    } else {
      current.add(copy);
    }

    itineraries.value = current;
  }

  // ============================================================
  // STATUS SELESAI PER HARI
  // ============================================================
  //
  // Pengganti flag lama 'finishedManually' yang ditempel ke SEMUA
  // hari sekaligus (jadinya permanen untuk seluruh itinerary, dan
  // itinerary multi-hari langsung "mati" walau hari berikutnya belum
  // dijalani sama sekali). Sekarang statusnya ditempel per HARI
  // (field 'dayCompleted' di map hari yang bersangkutan saja), jadi:
  //
  // - Hari yang destinasinya sudah semua dikunjungi & dikonfirmasi
  //   user bisa ditandai selesai TANPA mematikan hari-hari lain.
  // - Begitu tanggal hari berikutnya tiba, hari itu otomatis dianggap
  //   "aktif" lagi oleh TripScreen (lihat _findActiveTrip &
  //   _dayNumberToday di sana) karena tidak ada flag apa pun di
  //   level itinerary yang membuatnya diskip permanen.
  // - HistoryScreen tinggal cek hasAnyCompletedDay() supaya itinerary
  //   yang minimal satu harinya sudah selesai tetap ikut muncul di
  //   Riwayat, walau hari-hari lainnya belum/sedang berjalan.
  //
  // ============================================================

  void markDayCompleted(String itineraryId, int dayNumber) {
    final List<List<Map<String, dynamic>>> current =
        List<List<Map<String, dynamic>>>.from(itineraries.value);

    final int index = current.indexWhere((saved) => _idOf(saved) == itineraryId);
    if (index == -1) return;

    final List<Map<String, dynamic>> updated = current[index]
        .map((day) => Map<String, dynamic>.from(day))
        .toList();

    for (final day in updated) {
      if (_isDayNumber(day, dayNumber)) {
        day['dayCompleted'] = true;
      }
    }

    current[index] = updated;
    itineraries.value = current;
  }

  // True kalau hari [dayNumber] di [itinerary] ini sudah ditandai
  // selesai. false juga kalau hari itu tidak ketemu di data (belum
  // pernah ditandai == belum selesai).
  bool isDayCompleted(List<Map<String, dynamic>> itinerary, int dayNumber) {
    for (final schedule in itinerary) {
      if (_isDayNumber(schedule, dayNumber)) {
        return schedule['dayCompleted'] == true;
      }
    }
    return false;
  }

  // True kalau MINIMAL SATU hari di [itinerary] ini sudah ditandai
  // selesai -- dipakai HistoryScreen, lihat komentar di atas.
  bool hasAnyCompletedDay(List<Map<String, dynamic>> itinerary) {
    return itinerary.any((schedule) => schedule['dayCompleted'] == true);
  }

  // ============================================================
  // HAPUS SATU ITINERARY (BERDASARKAN ID-NYA)
  // ============================================================

  void remove(String itineraryId) {
    itineraries.value = itineraries.value
        .where((saved) => _idOf(saved) != itineraryId)
        .toList();
  }

  // ============================================================
  // HAPUS SEMUA ITINERARY
  // ============================================================

  void clear() {
    itineraries.value = [];
  }
}