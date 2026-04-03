import 'package:flutter/material.dart';

import 'chat_screen.dart';

/// Home screen – lists all conversations.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GemAI')),
      body: const _ConversationList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createConversation(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createConversation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChatScreen(conversationId: 0, title: 'New Chat'),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context) {
    // TODO: replace with ConversationsNotifier once wired.
    return const Center(
      child: Text('No conversations yet.\nTap + to start one.'),
    );
  }
}
