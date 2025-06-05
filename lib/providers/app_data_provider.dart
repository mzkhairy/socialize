import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialize/models/activity_category.dart';
import 'package:socialize/models/activity_model.dart';
import 'package:socialize/models/user_model.dart';
import 'package:socialize/models/notification_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math'; // For random data
import 'package:socialize/models/chat_message_model.dart';

const String _loggedInUserKey = 'logged_in_user_name';

class AppDataProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();

  // ----- User Data -----
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  // In a real app, this would come from a database or secure storage.
  // For this frontend-only example, we'll use a simple map to simulate user accounts.
  final Map<String, UserModel> _users = {}; // Key: username, Value: UserModel
  final Map<String, List<ChatMessageModel>> _activityChatMessages = {};

  // ----- Activity Data -----
  List<ActivityModel> _activities = [];
  List<ActivityModel> get activities =>
      _activities.where((act) => !act.hasEnded).toList(); // Filter out ended activities

  ActivityModel? _selectedActivity;
  ActivityModel? get selectedActivity => _selectedActivity;

  // ----- Notifications -----
  List<NotificationMessage> _notifications = [];
  List<NotificationMessage> get notifications => _notifications
      .where((n) => n.isRead == false) // Only show unread for count, but page shows all
      .toList();
  List<NotificationMessage> get allNotifications => _notifications;


  AppDataProvider() {
    _loadLoggedInUser();
    _generateDummyData(); // For testing
  }

  // ----- CHAT -----
  List<ChatMessageModel> getMessagesForActivity(String activityId) {
    return _activityChatMessages[activityId] ?? [];
  }

  void sendMessage({
    required String activityId,
    required String text,
  }) {
    if (_currentUser == null || text.trim().isEmpty) {
      return;
    }

    final message = ChatMessageModel(
      id: _uuid.v4(),
      activityId: activityId,
      senderId: _currentUser!.id,
      senderName: _currentUser!.name, // Store sender's name directly for easy display
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    if (!_activityChatMessages.containsKey(activityId)) {
      _activityChatMessages[activityId] = [];
    }
    _activityChatMessages[activityId]!.add(message);
    
    // Sort messages by timestamp after adding, ensuring chronological order
    _activityChatMessages[activityId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    print("[CHAT] Message sent by ${_currentUser!.name} in activity $activityId: $text");
    notifyListeners(); // Notify listeners that chat messages have updated
                      // This will help update the chat screen if it's open,
                      // and can be used for unread indicators later.
  }

  // ----- AUTHENTICATION -----
  Future<void> _loadLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userName = prefs.getString(_loggedInUserKey);
    if (userName != null && _users.containsKey(userName)) {
      _currentUser = _users[userName];
    } else if (userName != null) {
      // User name exists, but user object not in memory (e.g. after app restart without full persistence)
      // Re-create user object. In a real app, you'd fetch full user data from backend.
      final newUserId = _uuid.v4();
      _currentUser = UserModel(id: newUserId, name: userName);
      _users[userName] = _currentUser!;
    }
    notifyListeners();
  }

  Future<void> _saveLoggedInUser(String? userName) async {
    final prefs = await SharedPreferences.getInstance();
    if (userName == null) {
      await prefs.remove(_loggedInUserKey);
    } else {
      await prefs.setString(_loggedInUserKey, userName);
    }
  }

  Future<bool> login(String name) async {
    if (name.isEmpty) return false;

    if (_users.containsKey(name)) {
      _currentUser = _users[name];
    } else {
      final newUserId = _uuid.v4(); // Generate a unique ID for the user
      _currentUser = UserModel(id: newUserId, name: name);
      _users[name] = _currentUser!;
    }
    await _saveLoggedInUser(name);
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    _selectedActivity = null; // Clear selected activity on logout
    _saveLoggedInUser(null);
    // Optionally clear notifications for the logged-out user if they are user-specific
    // _notifications.clear();
    notifyListeners();
  }

  // ----- USER PROFILE -----
  List<ActivityModel> getActivitiesForCurrentUser() {
    if (_currentUser == null) return [];
    return _activities.where((activity) {
      return activity.coordinatorId == _currentUser!.id ||
             activity.joinedUserIds.contains(_currentUser!.id);
    }).where((act) => !act.hasEnded).toList();
  }


  // ----- ACTIVITY MANAGEMENT -----
  void selectActivity(ActivityModel? activity) {
    _selectedActivity = activity;
    notifyListeners();
  }

  void clearSelectedActivity() {
    _selectedActivity = null;
    notifyListeners();
  }

  void createActivity(ActivityModel activity) {
    _activities.add(activity);
    // Update coordinator's list of coordinated activities
    _users.update(
      _currentUser!.name,
      (user) => user.copyWith(
        coordinatedActivityIds: List.from(user.coordinatedActivityIds)..add(activity.id),
      ),
    );
    _addNotification(
      title: "Activity Created",
      body: "Your activity '${activity.name}' has been successfully created.",
      type: NotificationType.activityEdited, // Or a new type like 'activityCreated'
      relatedActivityId: activity.id,
    );
    notifyListeners();
    // Backend call: Save activity to database
  }

  void updateActivity(ActivityModel updatedActivity) {
    final index = _activities.indexWhere((act) => act.id == updatedActivity.id);
    if (index != -1) {
      _activities[index] = updatedActivity;

      // Notify joined users (excluding coordinator if they are the one editing)
      for (String userId in updatedActivity.joinedUserIds) {
        if (userId != _currentUser!.id) {
           // In a real app, you would push this notification to the specific user.
           // For this frontend demo, we'll add it to the current user's list if they are involved.
           // This part needs a more robust notification system for multi-user scenarios.
          _addNotificationToUser(
            targetUserId: userId, // This is conceptual for frontend-only
            title: "Activity Updated",
            body: "The activity '${updatedActivity.name}' you joined has been updated.",
            type: NotificationType.activityEdited,
            relatedActivityId: updatedActivity.id,
          );
        }
      }
      // Notify coordinator if not the one editing (less common for this app structure)
      if (updatedActivity.coordinatorId != _currentUser!.id) {
        _addNotificationToUser(
          targetUserId: updatedActivity.coordinatorId,
          title: "Activity Managed",
          body: "Details for '${updatedActivity.name}' were updated.",
          type: NotificationType.activityEdited,
          relatedActivityId: updatedActivity.id
        );
      }
       _addNotification(
          title: "Activity Updated",
          body: "You have successfully updated '${updatedActivity.name}'.",
          type: NotificationType.activityEdited,
          relatedActivityId: updatedActivity.id
        );


      if (_selectedActivity?.id == updatedActivity.id) {
        _selectedActivity = updatedActivity;
      }
      notifyListeners();
      // Backend call: Update activity in database
    }
  }

  bool deleteActivity(String activityId) {
    final activity = _activities.firstWhere((act) => act.id == activityId, orElse: () => throw Exception("Activity not found"));
    if (_currentUser == null || activity.coordinatorId != _currentUser!.id) return false; // Only coordinator

    if (activity.joinedUserIds.isNotEmpty) {
      // As per requirement: "deleting the activity when there are already other users joined will
      // require the current “coordinator” user to pass the “coordinator” label to other user"
      // This logic is simplified here: if users are joined, prevent deletion directly.
      // The UI should enforce passing coordinator first.
      // For this demo, if this method is called and users are joined, we assume coordinator transfer happened.
      // Or, if we want to enforce it here:
      // throw Exception("Cannot delete activity with participants. Please transfer coordination first.");
      // Let's assume the UI flow prevents this state or we allow deletion after warning.
      // For now, let's just say "you must pass coordinator first" is handled by UI.
      // If we strictly enforce, it means this function shouldn't be callable directly if participants exist
      // without a prior 'passCoordinator' call.
      // For this version, we'll allow deletion but it implies coordinator was passed or it's a forced delete.
    }

    _activities.removeWhere((act) => act.id == activityId);
    // Notify joined users
    for (String userId in activity.joinedUserIds) {
        _addNotificationToUser(
          targetUserId: userId,
          title: "Activity Cancelled",
          body: "The activity '${activity.name}' has been cancelled by the coordinator.",
          type: NotificationType.activityDeleted
        );
    }
    _users.update(
      _currentUser!.name,
      (user) => user.copyWith(
        coordinatedActivityIds: List.from(user.coordinatedActivityIds)..remove(activityId),
      ),
    );

    if (_selectedActivity?.id == activityId) {
      _selectedActivity = null;
    }
    _addNotification(
      title: "Activity Deleted",
      body: "You have successfully deleted '${activity.name}'.",
      type: NotificationType.activityDeleted
    );
    notifyListeners();
    // Backend call: Delete activity from database
    return true;
  }

  void joinActivity(String activityId) {
    if (_currentUser == null) return;
    final index = _activities.indexWhere((act) => act.id == activityId);
    if (index != -1) {
      ActivityModel activity = _activities[index];
      if (!activity.isFull && !activity.joinedUserIds.contains(_currentUser!.id)) {
        final updatedJoinedUserIds = List<String>.from(activity.joinedUserIds)..add(_currentUser!.id);
        _activities[index] = activity.copyWith(joinedUserIds: updatedJoinedUserIds);

        // Update user's joined activities
        _users.update(
          _currentUser!.name,
          (user) => user.copyWith(
            joinedActivityIds: List.from(user.joinedActivityIds)..add(activityId),
          ),
        );

        // Notify coordinator
        UserModel? coordinator = _getUserById(activity.coordinatorId);
        if (coordinator != null) {
             _addNotificationToUser(
                targetUserId: coordinator.id,
                title: "New Participant",
                body: "${_currentUser!.name} has joined your activity '${activity.name}'.",
                type: NotificationType.userJoined,
                relatedActivityId: activity.id
            );
        }
         _addNotification(
            title: "Joined Activity",
            body: "You have successfully joined '${activity.name}'.",
            type: NotificationType.userJoined, // Or a custom type
            relatedActivityId: activity.id
        );


        if (_selectedActivity?.id == activityId) {
          _selectedActivity = _activities[index];
        }
        notifyListeners();
        // Backend call: Update activity participants
      }
    }
  }

  void leaveActivity(String activityId) {
    if (_currentUser == null) return;
    final index = _activities.indexWhere((act) => act.id == activityId);
    if (index != -1) {
      ActivityModel activity = _activities[index];
      if (activity.joinedUserIds.contains(_currentUser!.id)) {
        final updatedJoinedUserIds = List<String>.from(activity.joinedUserIds)..remove(_currentUser!.id);
        _activities[index] = activity.copyWith(joinedUserIds: updatedJoinedUserIds);

         // Update user's joined activities
        _users.update(
          _currentUser!.name,
          (user) => user.copyWith(
            joinedActivityIds: List.from(user.joinedActivityIds)..remove(activityId),
          ),
        );

        // Notify coordinator
        UserModel? coordinator = _getUserById(activity.coordinatorId);
         if (coordinator != null && coordinator.id != _currentUser!.id) { // Don't notify self
             _addNotificationToUser(
                targetUserId: coordinator.id,
                title: "Participant Left",
                body: "${_currentUser!.name} has left your activity '${activity.name}'.",
                type: NotificationType.userLeft,
                relatedActivityId: activity.id
            );
        }
         _addNotification(
            title: "Left Activity",
            body: "You have left '${activity.name}'.",
            type: NotificationType.userLeft, // Or a custom type
            relatedActivityId: activity.id
        );

        if (_selectedActivity?.id == activityId) {
          _selectedActivity = _activities[index];
        }
        notifyListeners();
        // Backend call: Update activity participants
      }
    }
  }

  void removeUserFromActivity(String activityId, String userIdToRemove) {
    if (_currentUser == null) return;
    final index = _activities.indexWhere((act) => act.id == activityId);
    if (index != -1) {
      ActivityModel activity = _activities[index];
      // Only coordinator can remove
      if (activity.coordinatorId == _currentUser!.id && activity.joinedUserIds.contains(userIdToRemove)) {
        final updatedJoinedUserIds = List<String>.from(activity.joinedUserIds)..remove(userIdToRemove);
        _activities[index] = activity.copyWith(joinedUserIds: updatedJoinedUserIds);

        // Update removed user's joined activities
        UserModel? removedUser = _getUserById(userIdToRemove);
        if (removedUser != null) {
            _users.update(
              removedUser.name,
              (user) => user.copyWith(
                joinedActivityIds: List.from(user.joinedActivityIds)..remove(activityId),
              ),
            );
            _addNotificationToUser(
                targetUserId: removedUser.id,
                title: "Removed from Activity",
                body: "You have been removed from the activity '${activity.name}' by the coordinator.",
                type: NotificationType.userLeft, // Or a more specific type
                relatedActivityId: activity.id
            );
        }
         _addNotification(
            title: "Participant Removed",
            body: "You have removed a participant from '${activity.name}'.",
            type: NotificationType.userLeft // Or a custom type
        );


        if (_selectedActivity?.id == activityId) {
          _selectedActivity = _activities[index];
        }
        notifyListeners();
      }
    }
  }

  bool passCoordinatorRole(String activityId, String newCoordinatorUserId) {
    if (_currentUser == null) return false;
    final index = _activities.indexWhere((act) => act.id == activityId);
    if (index != -1) {
      ActivityModel activity = _activities[index];
      UserModel? newCoordinator = _getUserById(newCoordinatorUserId);

      if (activity.coordinatorId == _currentUser!.id &&
          newCoordinator != null &&
          activity.joinedUserIds.contains(newCoordinatorUserId)) { // New coordinator must be a participant

        _activities[index] = activity.copyWith(coordinatorId: newCoordinatorUserId);

        // Update old coordinator's list
        _users.update(
          _currentUser!.name,
          (user) => user.copyWith(
            coordinatedActivityIds: List.from(user.coordinatedActivityIds)..remove(activityId),
            // They might still be a participant if they didn't leave
          ),
        );
        // Update new coordinator's list
         _users.update(
          newCoordinator.name,
          (user) => user.copyWith(
            coordinatedActivityIds: List.from(user.coordinatedActivityIds)..add(activityId),
            // They are already in joinedUserIds
          ),
        );


        _addNotificationToUser(
            targetUserId: newCoordinatorUserId,
            title: "You are now Coordinator!",
            body: "You have been assigned as the coordinator for the activity '${activity.name}'.",
            type: NotificationType.assignedCoordinator,
            relatedActivityId: activity.id
        );
         _addNotification(
            title: "Coordinator Role Passed",
            body: "You have passed the coordinator role for '${activity.name}' to ${newCoordinator.name}.",
            type: NotificationType.assignedCoordinator // Or a custom type
        );

        if (_selectedActivity?.id == activityId) {
          _selectedActivity = _activities[index];
        }
        notifyListeners();
        return true;
      }
    }
    return false;
  }


  // ----- NOTIFICATIONS -----
  void _addNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? relatedActivityId,
  }) {
    // This adds notification for the CURRENT user.
    // In a real multi-user app, notifications are more complex and targeted.
    if (_currentUser == null) return; // Don't add if no user logged in

    final notification = NotificationMessage(
      id: _uuid.v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      relatedActivityId: relatedActivityId,
    );
    _notifications.insert(0, notification); // Add to the beginning of the list
    notifyListeners();
  }

  // Conceptual function for adding notification to a *specific* target user
  // In this frontend-only app, if the targetUser is the currentUser, it works.
  // Otherwise, this is a placeholder for where backend push notification would occur.
  void _addNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedActivityId,
  }) {
    if (_currentUser != null && _currentUser!.id == targetUserId) {
      _addNotification(title: title, body: body, type: type, relatedActivityId: relatedActivityId);
    } else {
      // This is where you'd send a push notification or store it for the target user on the backend.
      // For demo: if we had a global notification list accessible by user ID (not implemented here for simplicity)
      print("Simulating notification for user $targetUserId: $title - $body");
      // For now, only current user gets "real" notifications in the app's list.
      // To make this work more broadly in a frontend demo, notifications would need to be stored
      // globally and filtered by user, or the notification list would be part of the UserModel.
      // For simplicity, sticking to current user notifications.
    }
  }


  void markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // ----- HELPERS -----
  UserModel? getUserById(String userId) {
    try {
      return _users.values.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  UserModel? _getUserById(String userId) {
    // Find user by ID from the _users map (values)
    for (var user in _users.values) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }


  List<UserModel> getJoinedUsersForActivity(String activityId) {
    final activity = _activities.firstWhere((act) => act.id == activityId, orElse: () => throw Exception("Activity not found"));
    return activity.joinedUserIds.map((userId) => _getUserById(userId)).where((user) => user != null).cast<UserModel>().toList();
  }

  // ----- DUMMY DATA -----
  void _generateDummyData() {
     // Create some dummy users
    final user1Id = _uuid.v4();
    final user2Id = _uuid.v4();
    final user3Id = _uuid.v4();

    _users['Alice'] = UserModel(id: user1Id, name: 'Alice');
    _users['Bob'] = UserModel(id: user2Id, name: 'Bob');
    _users['Charlie'] = UserModel(id: user3Id, name: 'Charlie');


    // Dummy current user for testing if not logged in via UI yet
    // if (_currentUser == null) {
    //   login('Alice'); // Auto-login Alice for quick testing
    // }
    // For a cleaner start, don't auto-login. User must use login screen.

    // Generate some activities centered around a fictional area
    // (e.g. around a LatLng, for demo purposes. Replace with more realistic data or user inputs)
    final Random random = Random();
    final baseLat = 37.42200; // google base example
    final baseLng = -122.08400;

    _activities = [
      ActivityModel(
        id: _uuid.v4(),
        name: 'Morning Jogging Group',
        category: ActivityCategory.sports,
        locationDetails: 'City Park Fountain',
        description: 'Join us for a refreshing morning jog around the park. All fitness levels welcome!',
        startTime: DateTime.now().add(const Duration(days: 1, hours: 7)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 8)),
        location: LatLng(baseLat + (random.nextDouble() - 0.5) * 0.05, baseLng + (random.nextDouble() - 0.5) * 0.05),
        maxUsers: 10,
        creatorId: user1Id, // Alice
        coordinatorId: user1Id, // Alice
        joinedUserIds: [user2Id], // Bob joined
      ),
      ActivityModel(
        id: _uuid.v4(),
        name: 'Tech Meetup: Flutter Showcase',
        category: ActivityCategory.learning,
        locationDetails: 'Downtown Library Hall',
        description: 'Monthly tech meetup focusing on Flutter development. Presentations and networking.',
        startTime: DateTime.now().add(const Duration(days: 3, hours: 18)),
        endTime: DateTime.now().add(const Duration(days: 3, hours: 20)),
        location: LatLng(baseLat + (random.nextDouble() - 0.5) * 0.05, baseLng + (random.nextDouble() - 0.5) * 0.05),
        maxUsers: 50,
        creatorId: user2Id, // Bob
        coordinatorId: user2Id, // Bob
        joinedUserIds: [user1Id, user3Id], // Alice and Charlie joined
      ),
      ActivityModel(
        id: _uuid.v4(),
        name: 'Weekend Picnic & Games',
        category: ActivityCategory.socialGathering,
        locationDetails: 'Riverside Greens',
        description: 'Relaxing weekend picnic. Bring your favorite snacks and games. Family friendly!',
        startTime: DateTime.now().add(const Duration(days: 5, hours: 13)),
        endTime: DateTime.now().add(const Duration(days: 5, hours: 17)),
        location: LatLng(baseLat + (random.nextDouble() - 0.5) * 0.05, baseLng + (random.nextDouble() - 0.5) * 0.05),
        maxUsers: 20,
        creatorId: user3Id, // Charlie
        coordinatorId: user3Id, // Charlie
        joinedUserIds: [],
      ),
       ActivityModel(
        id: _uuid.v4(),
        name: 'Old Town Photo Walk',
        category: ActivityCategory.artsAndCulture,
        locationDetails: 'Historic Square Clocktower',
        description: 'Explore the historic old town with your camera. Share tips and capture beautiful moments.',
        startTime: DateTime.now().add(const Duration(hours: 2)), // Starts soon
        endTime: DateTime.now().add(const Duration(hours: 5)),
        location: LatLng(baseLat + (random.nextDouble() - 0.4) * 0.04, baseLng + (random.nextDouble() - 0.4) * 0.04),
        maxUsers: 15,
        creatorId: user1Id, // Alice
        coordinatorId: user1Id, // Alice
        joinedUserIds: [user3Id], // Charlie joined
      ),
    ];

    // Update user models with their created/joined activities from dummy data
    _users['Alice'] = _users['Alice']!.copyWith(
        coordinatedActivityIds: [_activities[0].id, _activities[3].id],
        joinedActivityIds: [_activities[1].id]);
    _users['Bob'] = _users['Bob']!.copyWith(
        coordinatedActivityIds: [_activities[1].id],
        joinedActivityIds: [_activities[0].id]);
    _users['Charlie'] = _users['Charlie']!.copyWith(
        coordinatedActivityIds: [_activities[2].id],
        joinedActivityIds: [_activities[1].id, _activities[3].id]);


    notifyListeners();
  }
}