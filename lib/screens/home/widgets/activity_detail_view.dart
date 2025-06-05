import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialize/models/activity_model.dart';
import 'package:socialize/models/user_model.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/screens/activity/create_edit_activity_screen.dart';
import 'package:socialize/screens/chat/activity_chat_screen.dart'; // Import Chat Screen
import 'package:socialize/utils/helpers.dart'; // For formatDateTimeRange
import 'package:socialize/models/activity_category.dart'; // For categoryToString

class ActivityDetailView extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onClose; // To switch back to list view

  const ActivityDetailView({
    super.key,
    required this.activity,
    required this.onClose,
  });

  List<Widget> _getActionButtons(
    BuildContext context,
    AppDataProvider appDataProvider,
    UserModel currentUser,
    bool isCoordinator,
    bool hasJoined,
    bool isFull,
  ) {
    List<Widget> buttons = [];
    final theme = Theme.of(context);

    // Main action button (Join/Leave/Manage)
    Widget mainActionButton;
    if (isCoordinator) {
      mainActionButton = ElevatedButton.icon(
        icon: const Icon(Icons.edit_note),
        label: const Text('Manage'), // Shortened for Row
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateEditActivityScreen(activityToEdit: activity),
            ),
          );
        },
      );
    } else if (hasJoined) {
      mainActionButton = ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Leave'), // Shortened for Row
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
        ),
        onPressed: () {
          _showConfirmationDialog( // Using the local method
            context,
            title: "Leave Activity?",
            content: "Are you sure you want to leave '${activity.name}'?",
            onConfirm: () {
              appDataProvider.leaveActivity(activity.id);
              // onClose(); // Optionally close detail view after leaving, or let it update
            }
          );
        },
      );
    } else if (isFull) {
      mainActionButton = ElevatedButton(
        onPressed: null, // Disabled
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        child: const Text('Full'), // Shortened for Row
      );
    } else {
      mainActionButton = ElevatedButton.icon(
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Join'), // Shortened for Row
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
        ),
        onPressed: () {
          appDataProvider.joinActivity(activity.id);
        },
      );
    }
    buttons.add(Expanded(child: mainActionButton));


    // Chat Room Button - only if joined or is coordinator
    if (hasJoined || isCoordinator) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 10)); // Spacing between buttons
      }
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
            label: Text('Chat', style: TextStyle(color: theme.colorScheme.primary)), // Shortened
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.7)),
              padding: const EdgeInsets.symmetric(vertical: 12), // Ensure similar height
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActivityChatScreen(
                    activityId: activity.id,
                    activityName: activity.name,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return buttons;
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).iconTheme.color?.withOpacity(0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              )
            )
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
    Color? confirmColor
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
              child: Text('Confirm', style: TextStyle(color: confirmColor ?? Theme.of(context).colorScheme.error)),
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


  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context);
    final currentUser = appDataProvider.currentUser;
    final theme = Theme.of(context);

    if (currentUser == null) {
      // This should ideally be handled before navigating here, or show a proper error state.
      return const Center(child: Text("User not logged in."));
    }

    bool isCoordinator = activity.coordinatorId == currentUser.id;
    bool hasJoined = activity.joinedUserIds.contains(currentUser.id);
    bool isFull = activity.isFull;

    UserModel? coordinator = appDataProvider.getUserById(activity.coordinatorId);

    return Container(
      // This container defines the panel's appearance
      decoration: BoxDecoration(
        color: theme.cardColor, // Adapts to theme
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SingleChildScrollView( // Makes the content scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisSize: MainAxisSize.min, // Not needed when inside SingleChildScrollView usually
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    activity.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: "Close Details",
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.people_alt_outlined, size: 20, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text('${activity.joinedUserIds.length} / ${activity.maxUsers} joined', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Chip(
                  label: Text(
                    categoryToString(activity.category), // Ensure categoryToString is imported
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSecondaryContainer),
                  ),
                  backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activity.locationDetails.isNotEmpty) // Changed from nearbyLandmark
              _buildDetailRow(context, Icons.info_outline, 'Details: ${activity.locationDetails}'),
            _buildDetailRow(context, Icons.calendar_today_outlined, formatDateTimeRange(activity.startTime, activity.endTime)),
             if (coordinator != null)
              _buildDetailRow(context, Icons.admin_panel_settings_outlined, 'Coordinator: ${coordinator.name}${isCoordinator ? " (You)" : ""}'),

            const SizedBox(height: 12),
            Text(
              'Description:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              activity.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20), // Spacing before buttons

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _getActionButtons(context, appDataProvider, currentUser, isCoordinator, hasJoined, isFull),
            ),
            const SizedBox(height: 8),

            // Conditional helper text below buttons
            if (isCoordinator && hasJoined && activity.joinedUserIds.length >= activity.maxUsers && !isFull) // This case might be rare if isFull is accurate
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '*You are the coordinator.',
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              )
            else if (!isCoordinator && hasJoined)
               Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '*You already joined this activity.',
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              )
            else if (!isCoordinator && !hasJoined && isFull)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '*The participant list is full.',
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16), // Padding at the bottom of the scroll view
          ],
        ),
      ),
    );
  }
}