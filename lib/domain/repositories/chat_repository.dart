import '../entities/chat_message.dart';
import '../entities/conversation.dart';

/// Abstract repository contract for the chat feature.
///
/// Defines the operations available for managing conversations and
/// messages. Implemented by the data layer with no knowledge of
/// storage or AI implementation details.
abstract interface class ChatRepository {
  /// Returns all conversations, most recent first.
  Future<List<Conversation>> getConversations();

  /// Creates a new conversation with the given [title].
  Future<Conversation> createConversation(String title);

  /// Renames the conversation identified by [id].
  Future<void> updateConversationTitle(int id, String title);

  /// Deletes the conversation identified by [id] and all its messages.
  Future<void> deleteConversation(int id);

  /// Returns all messages for a given [conversationId].
  Future<List<ChatMessage>> getMessages(int conversationId);

  /// Sends a user message (with optional [imagePath]) and returns the AI reply.
  Future<ChatMessage> sendMessage({
    required int conversationId,
    required String content,
    String? imagePath,
  });
}
