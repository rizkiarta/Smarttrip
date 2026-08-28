import 'package:flutter/material.dart';
import 'api_service.dart';

class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String description;
  final String icon;
  final bool isRead;
  final String timeAgo;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.isRead,
    required this.timeAgo,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'] ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'info',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      timeAgo: json['time_ago']?.toString() ?? 'Baru saja',
      createdAt: parsedDate,
    );
  }
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final ValueNotifier<List<NotificationModel>> notifications =
      ValueNotifier<List<NotificationModel>>([]);

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Fetch notifications from backend API
  Future<void> fetchNotifications() async {
    if (!ApiService.instance.isAuthenticated) return;
    isLoading.value = true;
    try {
      final res = await ApiService.instance.get('notifications');
      if (res != null && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        notifications.value = list;
        unreadCount.value = res['unread_count'] is int ? res['unread_count'] : 0;
        debugPrint('🔔 [NOTIFICATION SERVICE] Loaded ${list.length} notifications (${unreadCount.value} unread)');
      }
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE FETCH ERROR] $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (!ApiService.instance.isAuthenticated) return;
    try {
      await ApiService.instance.post('notifications/mark-read');
      // Update local state immediately
      notifications.value = notifications.value.map((n) {
        return NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          description: n.description,
          icon: n.icon,
          isRead: true,
          timeAgo: n.timeAgo,
          createdAt: n.createdAt,
        );
      }).toList();
      unreadCount.value = 0;
    } catch (e) {
      debugPrint('❌ [MARK ALL READ ERROR] $e');
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(int id) async {
    if (!ApiService.instance.isAuthenticated) return;
    try {
      await ApiService.instance.post('notifications/$id/read');
      notifications.value = notifications.value.map((n) {
        if (n.id == id) {
          return NotificationModel(
            id: n.id,
            type: n.type,
            title: n.title,
            description: n.description,
            icon: n.icon,
            isRead: true,
            timeAgo: n.timeAgo,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      unreadCount.value = (unreadCount.value - 1).clamp(0, 9999);
    } catch (e) {
      debugPrint('❌ [MARK READ ERROR] $e');
    }
  }
}
