import '../entities/chat_message.dart';
import '../entities/conversation.dart';

/// Abstract repository contract for the chat feature.
abstract interface class ChatRepository {
  Future<List<Conversation>> getConversations();
  Future<Conversation> createConversation(String title);
  Future<void> deleteConversation(int id);

  Future<List<ChatMessage>> getMessages(int conversationId);
  Future<ChatMessage> sendMessage({
    required int conversationId,
    required String content,
  });
}
