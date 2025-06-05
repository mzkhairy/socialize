// lib/screens/chat/activity_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialize/models/activity_model.dart'; // For Activity Name potentially
import 'package:socialize/models/chat_message_model.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/screens/chat/widgets/chat_message_bubble.dart';

class ActivityChatScreen extends StatefulWidget {
  final String activityId;
  final String activityName; // Passed for the AppBar title

  const ActivityChatScreen({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  State<ActivityChatScreen> createState() => _ActivityChatScreenState();
}

class _ActivityChatScreenState extends State<ActivityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }
    Provider.of<AppDataProvider>(context, listen: false).sendMessage(
      activityId: widget.activityId,
      text: _messageController.text,
    );
    _messageController.clear();
    _scrollToBottom(); // Scroll after sending
  }

  void _scrollToBottom() {
    // Ensure the scroll controller is attached and there's content
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) { // Schedule after build
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Scroll to bottom when messages load or change if we are near the bottom
    // This is a common pattern, but might need refinement for perfect behavior
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityName, overflow: TextOverflow.ellipsis),
        // elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AppDataProvider>( // Use Consumer to rebuild when messages change
              builder: (context, appData, child) {
                final messages = appData.getMessagesForActivity(widget.activityId);
                if (messages.isEmpty) {
                  return const Center(
                    child: Text("No messages yet. Say hi! 👋"),
                  );
                }
                // Scroll to bottom when new messages arrive and list rebuilds
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: theme.cardColor, // Or scaffoldBackgroundColor
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.05),
                )
              ],
            ),
            child: SafeArea( // Ensures text field isn't obscured by system UI
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      autocorrect: true,
                      enableSuggestions: true,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: _sendMessage,
                    padding: const EdgeInsets.all(12.0), 
                    splashRadius: 24.0, 
                    tooltip: "Send message",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}