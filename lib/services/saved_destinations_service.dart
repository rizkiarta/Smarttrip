import 'package:flutter/material.dart';

import '../data/destinations_data.dart';

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

class SavedDestinationsService {
  SavedDestinationsService._internal();

  static final SavedDestinationsService instance =
      SavedDestinationsService._internal();

  // Kunci pakai 'id' destinasi (sama seperti findDestinationById),
  // bukan 'name', supaya konsisten dengan cara layar lain
  // mereferensikan destinasi.
  final ValueNotifier<Set<String>> savedIds = ValueNotifier<Set<String>>(
    <String>{},
  );

  bool isSaved(String id) => savedIds.value.contains(id);

  void toggle(String id) {
    final updated = Set<String>.from(savedIds.value);

    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }

    savedIds.value = updated;
  }

  // Daftar destinasi tersimpan, diambil ulang dari kDestinationsData
  // lewat id supaya datanya (nama, gambar, rating, dst) selalu
  // konsisten dengan satu sumber data pusat.
  List<Map<String, String>> get savedDestinations {
    return savedIds.value
        .map(findDestinationById)
        .whereType<Map<String, String>>()
        .toList();
  }
}
