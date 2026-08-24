import 'package:flutter/material.dart';

// ================================================================
// MY REVIEWS SERVICE
// ================================================================
//
// Sumber kebenaran tunggal (single source of truth) untuk semua
// ulasan yang ditulis USER SENDIRI, lintas destinasi. Dipakai
// bersama oleh ReviewScreen (review_screen.dart) -- setiap kali
// user kirim ulasan baru, ulasan itu juga dicatat di sini -- dan
// ProfileScreen (profile_screen.dart) -> "Ulasan Saya" (menampilkan
// semua ulasan yang pernah ditulis user, dari destinasi manapun).
//
// Polanya sama seperti SavedDestinationsService: disimpan in-memory
// lewat ValueNotifier bawaan Flutter selama aplikasi berjalan.
//
// ================================================================

class MyReviewEntry {
  final String destinationId;
  final String destinationName;
  final String avatar;
  final String name;
  final double rating;
  final String time;
  final String text;
  final List<String> photos;
  String likes;
  bool liked;

  MyReviewEntry({
    required this.destinationId,
    required this.destinationName,
    required this.avatar,
    required this.name,
    required this.rating,
    required this.time,
    required this.text,
    required this.photos,
    this.likes = '0',
    this.liked = false,
  });
}

class MyReviewsService {
  MyReviewsService._internal();

  static final MyReviewsService instance = MyReviewsService._internal();

  final ValueNotifier<List<MyReviewEntry>> reviews =
      ValueNotifier<List<MyReviewEntry>>(<MyReviewEntry>[]);

  void addReview(MyReviewEntry entry) {
    reviews.value = [entry, ...reviews.value];
  }

  bool get isEmpty => reviews.value.isEmpty;
}