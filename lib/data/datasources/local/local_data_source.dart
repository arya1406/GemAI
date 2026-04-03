import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';

/// Contract for the local database data source.
abstract interface class LocalDataSource {
  // Conversations
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel> createConversation(String title);
  Future<void> deleteConversation(int id);

  // Messages
  Future<List<ChatMessageModel>> getMessages(int conversationId);
  Future<ChatMessageModel> insertMessage(ChatMessageModel message);
}
