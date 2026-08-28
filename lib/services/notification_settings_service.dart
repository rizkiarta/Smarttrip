import 'package:flutter/material.dart';
import 'api_service.dart';

// ================================================================
// NOTIFICATION SETTINGS SERVICE
// ================================================================
//
// NotificationSettingsService terhubung ke backend Laravel API
// (/api/v1/settings/notifications). Mengatur preferensi notifikasi
// user secara konsisten dan siap untuk integrasi push notification/FCM.
//
// ================================================================

class NotificationSettingsService {
  NotificationSettingsService._internal();

  static final NotificationSettingsService instance =
      NotificationSettingsService._internal();

  final ValueNotifier<bool> crowdAlerts = ValueNotifier<bool>(true);
  final ValueNotifier<bool> recommendationAlerts = ValueNotifier<bool>(true);
  final ValueNotifier<bool> itineraryReminders = ValueNotifier<bool>(true);
  final ValueNotifier<bool> promoAlerts = ValueNotifier<bool>(false);

  /// Fetch notification settings from Laravel backend
  Future<void> fetchSettings() async {
    if (!ApiService.instance.isAuthenticated) return;
    try {
      final res = await ApiService.instance.get('settings/notifications');
      if (res != null && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        crowdAlerts.value = data['crowd_alerts'] == true;
        recommendationAlerts.value = data['recommendation_alerts'] == true;
        itineraryReminders.value = data['itinerary_reminders'] == true;
        promoAlerts.value = data['promo_alerts'] == true;
      }
    } catch (e) {
      debugPrint('Fetch notification settings error: $e');
    }
  }

  /// Toggle setting locally & sync with Laravel backend
  Future<void> toggle(ValueNotifier<bool> setting) async {
    setting.value = !setting.value;

    if (ApiService.instance.isAuthenticated) {
      try {
        final body = {
          'crowd_alerts': crowdAlerts.value,
          'recommendation_alerts': recommendationAlerts.value,
          'itinerary_reminders': itineraryReminders.value,
          'promo_alerts': promoAlerts.value,
        };
        await ApiService.instance.put('settings/notifications', body: body);
      } catch (e) {
        debugPrint('Sync notification settings error: $e');
      }
    }
  }
}
