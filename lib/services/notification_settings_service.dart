import 'package:flutter/material.dart';

// ================================================================
// NOTIFICATION SETTINGS SERVICE
// ================================================================
//
// NotificationSettingsService murni in-memory, pola sama seperti
// LanguageService -- nanti kalau sudah ada backend/push notification
// system beneran, tinggal method di service ini yang diisi (mis.
// simpan preferensi + daftar/batal topic FCM), pemanggil
// (NotificationSettingsScreen di profile_screen.dart) tidak perlu
// diubah.
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

  void toggle(ValueNotifier<bool> setting) {
    setting.value = !setting.value;
  }
}
