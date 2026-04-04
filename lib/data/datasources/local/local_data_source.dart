import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';

/// Contract for the local database data source.
///
/// All persistence operations go through this interface so that
/// the repository layer stays decoupled from the Drift implementation.
abstract interface class LocalDataSource {
  // ---- Conversations ----

  /// Returns all conversations ordered by most recent first.
  Future<List<ConversationModel>> getConversations();

  /// Creates a new conversation with the given [title].
  Future<ConversationModel> createConversation(String title);

  /// Updates the [title] of the conversation identified by [id].
  Future<void> updateConversationTitle(int id, String title);

  /// Deletes the conversation identified by [id] and all its messages.
  Future<void> deleteConversation(int id);

  // ---- Messages ----

  /// Returns all messages for the given [conversationId], ordered by time.
  Future<List<ChatMessageModel>> getMessages(int conversationId);

  /// Persists a new [message] and returns the saved copy with its id.
  Future<ChatMessageModel> insertMessage(ChatMessageModel message);
}
