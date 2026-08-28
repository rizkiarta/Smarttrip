import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'push_notification_service.dart';
import 'notification_service.dart';

class SavedItineraryService {
  SavedItineraryService._internal() {
    _loadFromLocalCache();
  }

  static final SavedItineraryService instance =
      SavedItineraryService._internal();

  final ValueNotifier<List<List<Map<String, dynamic>>>> itineraries =
      ValueNotifier<List<List<Map<String, dynamic>>>>([]);

  Future<void>? _activeSaveFuture;
  static const String _kLocalCacheKey = 'saved_itineraries_v1';

  bool get hasItinerary => itineraries.value.isNotEmpty;

  String? _idOf(List<Map<String, dynamic>> dailySchedules) {
    if (dailySchedules.isEmpty) return null;
    return dailySchedules.first['itineraryId']?.toString();
  }

  String? itineraryIdOf(List<Map<String, dynamic>> dailySchedules) {
    return _idOf(dailySchedules);
  }

  bool _isDayNumber(Map<String, dynamic> schedule, int dayNumber) {
    final dynamic day = schedule['day'];
    final int? parsed = day is int ? day : int.tryParse(day?.toString() ?? '');
    return parsed == dayNumber;
  }

  /// Load itineraries from local SharedPreferences cache on startup
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_kLocalCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final List<List<Map<String, dynamic>>> list = [];
        for (final item in decoded) {
          if (item is List) {
            final List<Map<String, dynamic>> daily = [];
            for (final day in item) {
              if (day is Map) {
                daily.add(Map<String, dynamic>.from(day));
              }
            }
            if (daily.isNotEmpty) {
              list.add(daily);
            }
          }
        }
        if (list.isNotEmpty) {
          itineraries.value = list;
        }
      }
    } catch (e) {
      debugPrint('Error loading itinerary local cache: $e');
    }
  }

  /// Save current itineraries to local SharedPreferences cache
  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(
        itineraries.value,
        toEncodable: (nonEncodable) {
          if (nonEncodable is DateTime) {
            return '${nonEncodable.year}-${nonEncodable.month.toString().padLeft(2, '0')}-${nonEncodable.day.toString().padLeft(2, '0')}';
          }
          return nonEncodable.toString();
        },
      );
      await prefs.setString(_kLocalCacheKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving itinerary local cache: $e');
    }
  }

  /// Fetch user itineraries from Laravel server
  Future<void> fetchItineraries() async {
    // If a save operation is currently in flight, wait for it to complete first!
    if (_activeSaveFuture != null) {
      await _activeSaveFuture;
    }

    if (!ApiService.instance.isAuthenticated) return;
    try {
      final res = await ApiService.instance.get('itineraries');
      if (res['data'] is List) {
        final List<List<Map<String, dynamic>>> parsedList = [];
        for (final item in res['data']) {
          final String itineraryId = item['id'].toString();
          final String title = item['title'] ?? 'Trip';
          final String startDate = item['start_date'] ?? '';
          final String endDate = item['end_date'] ?? '';
          final int participants = item['participants_count'] ?? 1;
          final String vehicle = item['vehicle_type'] ?? 'Mobil';
          final String startLoc = item['start_location'] ?? '';
          final String startLat = item['start_latitude']?.toString() ?? '';
          final String startLng = item['start_longitude']?.toString() ?? '';
          final String depTime = item['departure_time'] ?? '';
          final String destCity = item['destination_city'] ?? '';

          final List<dynamic> days = item['days'] ?? [];
          final List<Map<String, dynamic>> dailySchedules = [];

          for (final d in days) {
            final int dayNum = d['day_number'] ?? 1;
            final bool isCompleted = d['is_completed'] ?? false;
            final List<dynamic> rawItems = d['items'] ?? [];
            final List<Map<String, dynamic>> destinations = [];

            for (final it in rawItems) {
              if (it['destination'] != null) {
                final destMap = it['destination'];
                String img = '';
                if (destMap is Map) {
                  for (final key in ['main_image', 'image', 'mainImage', 'photo', 'cover_image', 'image_url']) {
                    final val = destMap[key]?.toString().trim();
                    if (val != null && val.isNotEmpty && val != 'null') {
                      img = val;
                      break;
                    }
                  }
                }
                destinations.add({
                  'id': destMap['id'],
                  'name': destMap['name'],
                  'location': destMap['location'],
                  'category': destMap['category'],
                  'latitude': destMap['latitude'] ?? destMap['lat'],
                  'longitude': destMap['longitude'] ?? destMap['lng'],
                  'image': img,
                  'arrivalTime': it['arrival_time'] ?? '',
                  'departureTime': it['departure_time'] ?? '',
                  'notes': it['notes'] ?? '',
                });
              }
            }

            dailySchedules.add({
              'itineraryId': itineraryId,
              'tripName': title,
              'startDate': startDate,
              'endDate': endDate,
              'participants': participants,
              'vehicle': vehicle,
              'startLocation': startLoc,
              'startLatitude': startLat,
              'startLongitude': startLng,
              'departureTime': depTime,
              'destinationCity': destCity,
              'destination': destCity,
              'day': dayNum,
              'dayCompleted': isCompleted,
              'destinations': destinations,
            });
          }

          if (dailySchedules.isNotEmpty) {
            parsedList.add(dailySchedules);
          }
        }

        // Retain any unsynced local itineraries (with non-numeric itineraryId)
        final List<List<Map<String, dynamic>>> currentLocal = itineraries.value;
        for (final localItem in currentLocal) {
          final String? localId = _idOf(localItem);
          if (localId != null && int.tryParse(localId) == null) {
            final bool existsInServer = parsedList.any((s) => _idOf(s) == localId);
            if (!existsInServer) {
              parsedList.add(localItem);
            }
          }
        }

        itineraries.value = parsedList;
        await _saveToLocalCache();
      }
    } catch (e) {
      debugPrint('Fetch itineraries error: $e');
    }
  }

  String _formatDateForApi(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String().split('T').first;
    if (value is DateTime) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    final String str = value.toString().trim();
    if (str.isEmpty) return DateTime.now().toIso8601String().split('T').first;
    final DateTime? parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    }
    return str.split(' ').first;
  }

  /// Save or update itinerary locally & sync to Laravel server
  Future<void> save(List<Map<String, dynamic>> dailySchedules) async {
    final saveCompleter = Future(() async {
      final List<Map<String, dynamic>> copy = List<Map<String, dynamic>>.from(
        dailySchedules.map((day) => Map<String, dynamic>.from(day)),
      );

      final String? existingId = _idOf(copy);

      final List<List<Map<String, dynamic>>> current =
          List<List<Map<String, dynamic>>>.from(itineraries.value);

      final int existingIndex = existingId != null
          ? current.indexWhere((saved) => _idOf(saved) == existingId)
          : -1;

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
      await _saveToLocalCache();

      // Trigger instant push notification banner for itinerary creation
      final firstDay = copy.first;
      final tripTitle = firstDay['tripName'] ?? firstDay['destinationCity'] ?? 'Rencana Perjalanan';
      PushNotificationService.instance.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Rencana Perjalanan Disimpan',
        body: 'Rencana perjalanan "$tripTitle" berhasil disimpan. Siapkan perlengkapan Anda!',
      );
      NotificationService.instance.fetchNotifications();

      // Sync to Laravel server
      if (ApiService.instance.isAuthenticated) {
        try {
          final firstDay = copy.first;

          final dynamic rawParticipants = firstDay['participants'];
          final int participantsCount = rawParticipants is int
              ? rawParticipants
              : (int.tryParse(rawParticipants?.toString().replaceAll(RegExp(r'\D'), '') ?? '') ?? 1);

          final dynamic rawLat = firstDay['startLatitude'] ?? firstDay['start_latitude'];
          final double? startLat = rawLat != null ? double.tryParse(rawLat.toString()) : null;

          final dynamic rawLng = firstDay['startLongitude'] ?? firstDay['start_longitude'];
          final double? startLng = rawLng != null ? double.tryParse(rawLng.toString()) : null;

          final payload = {
            'title': firstDay['tripName'] ?? 'Rencana Perjalanan',
            'start_date': _formatDateForApi(firstDay['startDate']),
            'end_date': _formatDateForApi(firstDay['endDate']),
            'participants_count': participantsCount,
            'vehicle_type': firstDay['vehicle'] ?? 'Mobil',
            'start_location': firstDay['startLocation'] ?? '',
            'start_latitude': startLat,
            'start_longitude': startLng,
            'departure_time': firstDay['departureTime'] ?? firstDay['departure_time'],
            'destination_city': firstDay['destinationCity'] ?? firstDay['destination'] ?? '',
            'days': copy.map((dayMap) {
              final List<dynamic> dests = dayMap['destinations'] ?? [];
              return {
                'day_number': dayMap['day'] ?? 1,
                'items': dests.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return {
                    'destination_id': item['id'] ?? item['destination_id'],
                    'sort_order': idx + 1,
                    'arrival_time': item['arrivalTime'],
                    'departure_time': item['departureTime'],
                    'notes': item['notes'],
                  };
                }).toList(),
              };
            }).toList(),
          };

          if (existingIndex != -1 && int.tryParse(itineraryId) != null) {
            await ApiService.instance.put('itineraries/$itineraryId', body: payload);
          } else {
            final res = await ApiService.instance.post('itineraries', body: payload);
            if (res['data'] != null && res['data']['id'] != null) {
              final serverId = res['data']['id'].toString();
              for (final day in copy) {
                day['itineraryId'] = serverId;
              }
              itineraries.value = List.from(itineraries.value);
              await _saveToLocalCache();
            }
          }
        } catch (e) {
          debugPrint('Sync save itinerary API error: $e');
        }
      }
    });

    _activeSaveFuture = saveCompleter;
    try {
      await saveCompleter;
    } finally {
      if (_activeSaveFuture == saveCompleter) {
        _activeSaveFuture = null;
      }
    }
  }

  /// Mark a day as completed locally & sync to server
  Future<void> markDayCompleted(String itineraryId, int dayNumber) async {
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
    await _saveToLocalCache();

    // Trigger instant push notification banner
    PushNotificationService.instance.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Progress Perjalanan Selesai',
      body: 'Selamat! Hari ke-$dayNumber dari perjalanan Anda berhasil ditandai selesai.',
    );
    NotificationService.instance.fetchNotifications();

    if (ApiService.instance.isAuthenticated && int.tryParse(itineraryId) != null) {
      try {
        await ApiService.instance.patch('itineraries/$itineraryId/days/$dayNumber/complete');
      } catch (e) {
        debugPrint('Mark day complete API error: $e');
      }
    }
  }

  bool isDayCompleted(List<Map<String, dynamic>> itinerary, int dayNumber) {
    for (final schedule in itinerary) {
      if (_isDayNumber(schedule, dayNumber)) {
        return schedule['dayCompleted'] == true;
      }
    }
    return false;
  }

  bool hasAnyCompletedDay(List<Map<String, dynamic>> itinerary) {
    return itinerary.any((schedule) => schedule['dayCompleted'] == true);
  }

  /// Remove an itinerary locally & sync to server
  Future<void> remove(String itineraryId) async {
    itineraries.value = itineraries.value
        .where((saved) => _idOf(saved) != itineraryId)
        .toList();
    await _saveToLocalCache();

    if (ApiService.instance.isAuthenticated && int.tryParse(itineraryId) != null) {
      try {
        await ApiService.instance.delete('itineraries/$itineraryId');
      } catch (e) {
        debugPrint('Remove itinerary API error: $e');
      }
    }
  }

  void clear() {
    itineraries.value = [];
    _saveToLocalCache();
  }
}