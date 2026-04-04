import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

/// Screen that shows a single conversation's messages.
///
/// Displays a scrollable message list with auto-scroll on new messages,
/// and a dynamic input bar for text, image, and voice inputs.
/// Optimistic user messages are shown immediately while the AI responds.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.conversationId,
    required this.title,
    super.key,
  });

  /// The database ID of the conversation.
  final int conversationId;

  /// Display title for the app bar.
  final String title;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  /// Messages added optimistically while waiting for the AI reply.
  final _pendingMessages = <ChatMessage>[];

  /// Whether the AI is currently processing a response.
  bool _isAiProcessing = false;

  /// Editable title for this conversation.
  late String _currentTitle = widget.title;

  /// Shows a dialog to rename this conversation.
  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _currentTitle);
    // Capture repo before async gap to avoid dependents error.
    final repo = ref.read(chatRepositoryProvider);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Enter new title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (newTitle != null && newTitle.isNotEmpty && newTitle != _currentTitle) {
      await repo.updateConversationTitle(widget.conversationId, newTitle);
      ref.invalidate(conversationsProvider);
      if (mounted) setState(() => _currentTitle = newTitle);
    }
  }

  /// Scrolls to the bottom after a short delay to allow the list to rebuild.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Sends a message, shows it optimistically, then refreshes from DB.
  Future<void> _onSend(String text, {String? imagePath}) async {
    final userMessage = ChatMessage(
      conversationId: widget.conversationId,
      role: 'user',
      messageType: imagePath != null ? 'image' : 'text',
      content: text,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    setState(() {
      _pendingMessages.add(userMessage);
      _isAiProcessing = true;
    });
    _scrollToBottom();

    try {
      await ref.read(sendMessageUseCaseProvider).call(
            conversationId: widget.conversationId,
            content: text,
            imagePath: imagePath,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingMessages.clear();
          _isAiProcessing = false;
        });
        ref.invalidate(chatMessagesProvider(widget.conversationId));
        ref.invalidate(conversationsProvider);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.conversationId));

    // Auto-scroll when persisted messages reload.
    ref.listen(chatMessagesProvider(widget.conversationId), (_, __) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename chat',
            onPressed: _showRenameDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                final allMessages = [...messages, ..._pendingMessages];
                return _MessageList(
                  messages: allMessages,
                  scrollController: _scrollController,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),

          // Typing indicator while the AI is processing.
          if (_isAiProcessing) const _TypingIndicator(),

          MessageInput(
            onSend: (text, {String? imagePath}) =>
                _onSend(text, imagePath: imagePath),
          ),
        ],
      ),
    );
  }
}

/// Scrollable list of chat bubbles.
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Send a message to start the chat.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (_, i) => ChatBubble(message: messages[i]),
    );
  }
}

/// Animated dots shown while the AI generates a response.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 600 + i * 200),
              builder: (_, value, child) => Opacity(
                opacity: 0.3 + 0.7 * value,
                child: child,
              ),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
