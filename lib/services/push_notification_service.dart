import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'api_service.dart';
import 'notification_service.dart';

// ================================================================
// BACKGROUND MESSAGE HANDLER
// ================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    debugPrint('🔔 [FCM BACKGROUND] Received message: ${message.messageId} | Title: ${message.notification?.title}');
  } catch (e) {
    debugPrint('❌ [FCM BACKGROUND ERROR] $e');
  }
}

// ================================================================
// PUSH NOTIFICATION SERVICE
// ================================================================

class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService instance = PushNotificationService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'smarttrip_push_channel',
    'SmartTrip Notifications',
    description: 'Notifikasi penting perjalanan, prediksi kepadatan, dan info SmartTrip',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialize Firebase Push Notifications & Local Notifications safely
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase App if needed
      await _ensureFirebaseInitialized();

      // 2. Request Notification Permissions
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 [FCM PERMISSION] Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // 3. Initialize Local Notifications Plugin (for foreground pop-ups)
        await _initLocalNotifications();

        // 4. Set Background Handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 5. Register FCM Token with Laravel Backend
        await registerFcmToken();

        // 6. Listen to Token Refresh
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔔 [FCM TOKEN REFRESHED] $newToken');
          _fcmToken = newToken;
          registerFcmToken();
        });

        // 7. Listen to Foreground Messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // 8. Handle Notification Clicks (App in background / opened via notification)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // 9. Handle Notification Click when app was terminated
        final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        _initialized = true;
        debugPrint('✅ [PUSH NOTIFICATION SERVICE] Fully initialized.');
      } else {
        debugPrint('⚠️ [PUSH NOTIFICATION SERVICE] Permission denied by user.');
      }
    } catch (e) {
      debugPrint('❌ [PUSH NOTIFICATION INIT ERROR] Safe fallback engaged: $e');
    }
  }

  /// Ensure Firebase is initialized cleanly
  Future<void> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [FIREBASE INIT WARNING] $e');
    }
  }

  /// Initialize Flutter Local Notifications plugin
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 [LOCAL NOTIF CLICKED] Payload: ${response.payload}');
        _handleLocalNotificationClick(response.payload);
      },
    );

    // Create Notification Channel for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Register / Sync FCM Token to Laravel Backend (`POST /api/v1/device-tokens`)
  Future<void> registerFcmToken() async {
    if (!ApiService.instance.isAuthenticated) return;

    try {
      await _ensureFirebaseInitialized();
      _fcmToken ??= await _messaging.getToken();
      if (_fcmToken == null || _fcmToken!.isEmpty) return;

      final body = {
        'fcm_token': _fcmToken,
        'device_type': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
      };

      await ApiService.instance.post('device-tokens', body: body);
      debugPrint('🚀 [FCM TOKEN SYNCED TO BACKEND] Token: ${_fcmToken!.substring(0, 15)}...');
    } catch (e) {
      debugPrint('❌ [FCM TOKEN SYNC ERROR] $e');
    }
  }

  /// Handle Foreground Notification (Show Heads-up Banner)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM FOREGROUND MESSAGE] ${message.notification?.title}');

    // 1. Refresh internal inbox notifications list
    NotificationService.instance.fetchNotifications();

    // 2. Display local heads-up notification banner
    final RemoteNotification? notification = message.notification;

    if (notification != null) {
      showLocalNotification(
        id: notification.hashCode,
        title: notification.title ?? 'SmartTrip',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle Notification Click from FCM
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 [FCM NOTIFICATION TAP] Data: ${message.data}');
    NotificationService.instance.fetchNotifications();
    // Payload data processing can trigger navigation if needed
  }

  /// Handle Local Notification Click
  void _handleLocalNotificationClick(String? payload) {
    NotificationService.instance.fetchNotifications();
  }

  /// Show Local Notification (Used for Trip Reminders, Emergency Crowd Alerts, & Foreground FCM)
  Future<void> showLocalNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'smarttrip_push_channel',
        'SmartTrip Notifications',
        channelDescription: 'Notifikasi penting perjalanan & informasi SmartTrip',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF55B8F4),
        playSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ [SHOW LOCAL NOTIFICATION ERROR] $e');
    }
  }

  /// Pengingat rencana perjalanan belum selesai
  Future<void> showUnfinishedTripReminder({
    required String itineraryTitle,
  }) async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Rencana Perjalanan Belum Selesai',
      body: 'Anda masih memiliki rencana perjalanan $itineraryTitle yang belum diselesaikan. Lanjutkan perjalanan Anda sekarang.',
    );
  }

  /// Informasi kondisi kepadatan destinasi favorit
  Future<void> showFavoriteCrowdUpdate({
    required String destinationName,
    String crowdStatus = 'sepi',
  }) async {
    final statusText = crowdStatus.toLowerCase() == 'sepi'
        ? 'diprediksi dalam kondisi sepi dan nyaman untuk dikunjungi hari ini.'
        : 'diprediksi dalam kondisi ramai pengunjung hari ini.';

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Kondisi Destinasi Favorit',
      body: 'Destinasi favorit Anda, $destinationName, $statusText',
    );
  }

  /// Show Trip Progress & Perjalanan Reminder (digunakan saat perjalanan/trip aktif)
  Future<void> showTripReminder({
    required String destinationName,
    required String message,
  }) async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Perjalanan: $destinationName',
      body: message,
    );
  }

  /// Show Crowd Alert
  Future<void> showCrowdAlert({
    required String destinationName,
    required String statusText,
  }) async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Informasi Kepadatan: $destinationName',
      body: statusText,
    );
  }
}
