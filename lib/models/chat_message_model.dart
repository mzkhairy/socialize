// lib/models/chat_message_model.dart
import 'package:flutter/foundation.dart';

@immutable
class ChatMessageModel {
  final String id;
  final String activityId;
  final String senderId;
  final String senderName; // To display who sent it
  final String text;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.activityId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });
}