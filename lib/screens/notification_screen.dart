import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.fetchNotifications();
  }

  Future<void> _onRefresh() async {
    await NotificationService.instance.fetchNotifications();
  }

  IconData _getNotificationIcon(String iconStr) {
    switch (iconStr) {
      case 'groups':
        return Icons.groups_rounded;
      case 'explore':
        return Icons.explore_outlined;
      case 'route':
        return Icons.route_outlined;
      case 'location':
        return Icons.location_on_outlined;
      case 'calendar':
        return Icons.calendar_today_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'crowd':
        return Colors.red;
      case 'recommendation':
        return AppColors.primaryBlue;
      case 'itinerary':
        return Colors.green;
      case 'favorite':
        return Colors.orange;
      default:
        return const Color(0xFF7B61FF);
    }
  }

  Color _getNotificationBg(String type) {
    switch (type) {
      case 'crowd':
        return AppColors.errorBg;
      case 'recommendation':
        return AppColors.lightBlue;
      case 'itinerary':
        return AppColors.successBg;
      case 'favorite':
        return const Color(0xFFFFF5E6);
      default:
        return const Color(0xFFF1EEFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: _onRefresh,
                child: ValueListenableBuilder<bool>(
                  valueListenable: NotificationService.instance.isLoading,
                  builder: (context, isLoading, _) {
                    return ValueListenableBuilder<List<NotificationModel>>(
                      valueListenable: NotificationService.instance.notifications,
                      builder: (context, notificationList, _) {
                        if (isLoading && notificationList.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.primaryBlue),
                          );
                        }

                        if (notificationList.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.notifications_off_outlined, size: 60, color: AppColors.greyText),
                                    SizedBox(height: 12),
                                    Text(
                                      'Belum ada notifikasi.',
                                      style: TextStyle(fontSize: 14, color: AppColors.greyText, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        final now = DateTime.now();
                        final todayNotifications = notificationList.where((n) {
                          final diff = now.difference(n.createdAt);
                          return diff.inHours < 24 && n.createdAt.day == now.day;
                        }).toList();

                        final earlierNotifications = notificationList.where((n) {
                          final diff = now.difference(n.createdAt);
                          return diff.inHours >= 24 || n.createdAt.day != now.day;
                        }).toList();

                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
                          children: [
                            if (todayNotifications.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(left: 5, bottom: 12),
                                child: Text(
                                  'Hari ini',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText),
                                ),
                              ),
                              ...todayNotifications.map((n) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildNotificationCard(n),
                                  )),
                              const SizedBox(height: 14),
                            ],
                            if (earlierNotifications.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(left: 5, bottom: 12),
                                child: Text(
                                  'Sebelumnya',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText),
                                ),
                              ),
                              ...earlierNotifications.map((n) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildNotificationCard(n),
                                  )),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderColorLight),
                  ),
                  child: const Icon(Icons.chevron_left, color: Color(0xFF555555), size: 27),
                ),
              ),
            ),
            const Text(
              'Notifikasi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  NotificationService.instance.markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi telah ditandai dibaca'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text(
                  'Tandai semua',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final IconData icon = _getNotificationIcon(notification.icon);
    final Color iconColor = _getNotificationColor(notification.type);
    final Color backgroundColor = _getNotificationBg(notification.type);

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          NotificationService.instance.markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 7),
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.4,
                      color: AppColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    notification.timeAgo,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}