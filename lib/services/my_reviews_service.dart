import 'dart:io';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'push_notification_service.dart';
import 'notification_service.dart';

class MyReviewEntry {
  final int? id;
  final String destinationId;
  final String destinationName;
  final String? avatar;
  final String name;
  final double rating;
  final String time;
  final String text;
  final List<String> photos;
  String likes;
  bool liked;

  MyReviewEntry({
    this.id,
    required this.destinationId,
    required this.destinationName,
    this.avatar,
    required this.name,
    required this.rating,
    required this.time,
    required this.text,
    required this.photos,
    this.likes = '0',
    this.liked = false,
  });

  factory MyReviewEntry.fromJson(Map<String, dynamic> json) {
    return MyReviewEntry(
      id: json['id'],
      destinationId: json['destination_id'] ?? '',
      destinationName: json['destination_name'] ?? 'Destinasi',
      avatar: json['user_avatar'],
      name: json['user_name'] ?? 'Pengguna SmartTrip',
      rating: (json['rating'] ?? 0).toDouble(),
      time: json['created_at'] ?? 'Baru saja',
      text: json['review_text'] ?? '',
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      likes: (json['likes_count'] ?? 0).toString(),
      liked: json['liked'] == true,
    );
  }
}

class MyReviewsService {
  MyReviewsService._internal();

  static final MyReviewsService instance = MyReviewsService._internal();

  final ValueNotifier<List<MyReviewEntry>> reviews =
      ValueNotifier<List<MyReviewEntry>>(<MyReviewEntry>[]);

  /// Fetch ulasan milik user yang sedang login dari server
  Future<void> fetchMyReviews() async {
    if (!ApiService.instance.isAuthenticated) return;
    try {
      final res = await ApiService.instance.get('users/me/reviews');
      if (res != null && res['data'] is List) {
        reviews.value = (res['data'] as List)
            .map((item) => MyReviewEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Fetch my reviews error: $e');
    }
  }

  /// Submit ulasan baru ke Laravel API
  /// Throws [ApiException] atau [Exception] jika gagal — caller wajib handle
  Future<void> addReview(
    MyReviewEntry entry, {
    List<File>? localImageFiles,
  }) async {
    if (entry.destinationId.isEmpty) {
      throw Exception('ID destinasi tidak valid.');
    }

    final safeId = Uri.encodeComponent(entry.destinationId);
    final fields = {
      'rating': entry.rating.toInt().toString(),
      'review_text': entry.text,
    };

    if (localImageFiles != null && localImageFiles.isNotEmpty) {
      await ApiService.instance.multipartPost(
        'destinations/$safeId/reviews',
        fields: fields,
        files: localImageFiles,
      );
    } else {
      await ApiService.instance.post(
        'destinations/$safeId/reviews',
        body: {
          'rating': entry.rating.toInt(),
          'review_text': entry.text,
        },
      );
    }

    // Sinkronisasi daftar ulasan saya dari server
    await fetchMyReviews();

    // Push notification banner instant
    PushNotificationService.instance.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Ulasan Berhasil Diterbitkan',
      body: 'Terima kasih telah mengulas ${entry.destinationName}! Ulasan Anda sangat bermanfaat bagi traveler lain.',
    );
    NotificationService.instance.fetchNotifications();
  }

  bool get isEmpty => reviews.value.isEmpty;
}