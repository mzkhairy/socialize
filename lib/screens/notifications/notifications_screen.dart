import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialize/models/notification_model.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/utils/helpers.dart'; // for formatDateTimeSimple

class NotificationsScreen extends StatelessWidget {
  static const String routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context);
    // Get all notifications, newest first (already handled by insert(0,...) in provider)
    final notifications = appDataProvider.allNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: "Clear All (Not Implemented)", // Mark as read for now
              onPressed: () {
                // For a real "clear all", you might want a confirmation
                // For now, let's make it "mark all as read" if needed, or just clear.
                // appDataProvider.clearAllNotifications();
                // As per current setup, notifications are just a list. "Clear all" would empty it.
                // Let's make it a simple clear for demo.
                 _showConfirmationDialog(context,
                    title: "Clear Notifications?",
                    content: "Are you sure you want to clear all notifications? This action cannot be undone.",
                    onConfirm: () {
                        appDataProvider.clearAllNotifications();
                        showAppSnackBar(context, "All notifications cleared.");
                    }
                 );
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No notifications yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: Icon(_getNotificationIcon(notification.type, context),
                    color: notification.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.body,
                         style: TextStyle(
                            color: notification.isRead ? Colors.grey : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDateTimeSimple(notification.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: notification.isRead ? null : const Icon(Icons.circle, color: Colors.blueAccent, size: 10),
                  onTap: () {
                    if (!notification.isRead) {
                      appDataProvider.markNotificationAsRead(notification.id);
                    }
                    if (notification.relatedActivityId != null) {
                      final activity = appDataProvider.activities
                          .firstWhere((act) => act.id == notification.relatedActivityId, orElse: () => throw StateError('Activity not found'));
                      if (activity != null) {
                        appDataProvider.selectActivity(activity);
                        // Navigate to home and show activity. Similar to profile screen nav.
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    }
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
    );
  }

  IconData _getNotificationIcon(NotificationType type, BuildContext context) {
    switch (type) {
      case NotificationType.userJoined:
        return Icons.person_add_alt_1_outlined;
      case NotificationType.userLeft:
        return Icons.person_remove_alt_1_outlined;
      case NotificationType.activityEdited:
        return Icons.edit_note_outlined;
      case NotificationType.activityDeleted:
        return Icons.delete_sweep_outlined;
      case NotificationType.assignedCoordinator:
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

   void _showConfirmationDialog(BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Confirm', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () {
                onConfirm();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}