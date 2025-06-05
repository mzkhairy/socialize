import 'package:flutter/foundation.dart';

enum NotificationType {
  userJoined,
  userLeft,
  activityEdited,
  activityDeleted,
  assignedCoordinator,
  // Could add more like activityStartingSoon, etc.
}

@immutable
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final String? relatedActivityId; // Optional: to navigate to the activity
  bool isRead;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.relatedActivityId,
    this.isRead = false,
  });
}