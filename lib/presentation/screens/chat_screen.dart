import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

/// Screen that shows a single conversation.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({
    required this.conversationId,
    required this.title,
    super.key,
  });

  final int conversationId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync =
        ref.watch(chatNotifierProvider(conversationId));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _MessageList(messages: messages),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          MessageInput(
            onSend: (text) => ref
                .read(chatNotifierProvider(conversationId).notifier)
                .sendMessage(text),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Text('Send a message to start the chat.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (_, i) => ChatBubble(message: messages[i]),
    );
  }
}
