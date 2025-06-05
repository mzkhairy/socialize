// lib/screens/chat/widgets/chat_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socialize/models/chat_message_model.dart';
import 'package:socialize/providers/app_data_provider.dart'; // To get current user
import 'package:provider/provider.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
    final bool isMe = message.senderId == appDataProvider.currentUser?.id;
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) // Show sender's name if not the current user
              Padding(
                padding: const EdgeInsets.only(bottom: 3.0),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isMe ? theme.colorScheme.onPrimary.withOpacity(0.8) : theme.colorScheme.onSecondaryContainer.withOpacity(0.8),
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.timestamp), // HH:mm for 24h
              style: TextStyle(
                fontSize: 10,
                color: isMe ? theme.colorScheme.onPrimary.withOpacity(0.7) : theme.colorScheme.onSecondaryContainer.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}