import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/user_notifications_controller.dart';
import 'package:otobix/Models/user_notifications_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Panel/user_notification_details_page.dart';
import 'package:otobix/Widgets/empty_data_widget.dart';

class UserNotificationsPage extends StatelessWidget {
  UserNotificationsPage({super.key});

  final UserNotificationsController getxController = Get.put(
    UserNotificationsController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Obx(
                () => Text(
                  getxController.unreadCount.value.toString(),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: getxController.markAllNotificationsAsRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (getxController.items.isEmpty && getxController.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (getxController.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: getxController.refreshList,
            child: ListView(
              children: const [
                SizedBox(height: 300),
                Center(
                  child: EmptyDataWidget(
                    icon: Icons.notifications_off,
                    message: 'No notifications yet',
                  ),
                ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (sn) {
            if (sn.metrics.pixels > sn.metrics.maxScrollExtent - 200 &&
                !getxController.loading.value) {
              getxController.fetchMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: getxController.refreshList,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: getxController.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder:
                  (_, i) => _NotifTile(
                    notification: getxController.items[i],
                    onTap: () async {
                      await getxController.markNotificationAsRead(
                        getxController.items[i].id!,
                      );
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => UserNotificationDetailsPage(
                                  id: getxController.items[i].id!,
                                ),
                          ),
                        );
                      }
                    },
                  ),
            ),
          ),
        );
      }),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final UserNotificationsModel notification;
  final VoidCallback onTap;
  const _NotifTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
      tileColor:
          notification.isRead
              ? AppColors.grey.withValues(alpha: .1)
              : AppColors.green.withValues(alpha: .2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.notifications, size: 25),
      title: Text(
        notification.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      subtitle: Text(
        notification.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12),
      ),
      trailing: Text(
        _ago(notification.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}
