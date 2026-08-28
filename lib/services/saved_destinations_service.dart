import 'package:flutter/material.dart';
import '../data/destinations_data.dart';
import 'api_service.dart';
import 'push_notification_service.dart';
import 'notification_service.dart';

class SavedDestinationsService {
  SavedDestinationsService._internal();

  static final SavedDestinationsService instance =
      SavedDestinationsService._internal();

  final ValueNotifier<Set<String>> savedIds = ValueNotifier<Set<String>>(
    <String>{},
  );

  final Map<String, Map<String, String>> _remoteCache = {};

  bool isSaved(String id) => savedIds.value.contains(id);

  /// Load user favorites from Laravel server
  Future<void> fetchFavorites() async {
    if (!ApiService.instance.isAuthenticated) return;
    try {
      final res = await ApiService.instance.get('favorites');
      if (res != null && res['data'] is List) {
        final List list = res['data'] as List;
        final Set<String> ids = {};
        for (final item in list) {
          if (item is Map) {
            final String id = item['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              ids.add(id);
              _remoteCache[id] = {
                'id': id,
                'name': item['name']?.toString() ?? 'Destinasi',
                'location': item['location']?.toString() ?? 'Lampung',
                'rating': (item['rating'] ?? '4.5').toString(),
                'reviews': (item['reviews'] ?? '0 review').toString(),
                'image': item['main_image']?.toString() ?? 'assets/images/placeholder.jpg',
                'description': item['description']?.toString() ?? '',
              };
            }
          }
        }
        savedIds.value = ids;
      }
    } catch (e) {
      debugPrint('Fetch favorites error: $e');
    }
  }

  /// Toggle favorite state locally & sync with server
  Future<void> toggle(String id) async {
    final updated = Set<String>.from(savedIds.value);
    final bool isAdding = !updated.contains(id);

    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    savedIds.value = updated;

    if (isAdding) {
      final destData = findDestinationById(id);
      final destName = destData?['name'] ?? 'Destinasi';
      PushNotificationService.instance.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Destinasi Favorit Ditambahkan',
        body: '$destName berhasil disimpan ke daftar favorit Anda. Kami akan memberikan kabar update kepadatan!',
      );
      NotificationService.instance.fetchNotifications();
    }

    if (ApiService.instance.isAuthenticated) {
      try {
        await ApiService.instance.post('favorites/$id/toggle');
      } catch (e) {
        debugPrint('Toggle favorite API error: $e');
      }
    }
  }

  List<Map<String, String>> get savedDestinations {
    final List<Map<String, String>> result = [];
    for (final id in savedIds.value) {
      final local = findDestinationById(id);
      if (local != null) {
        result.add(local);
      } else if (_remoteCache.containsKey(id)) {
        result.add(_remoteCache[id]!);
      }
    }
    return result;
  }
}
