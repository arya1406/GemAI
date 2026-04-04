import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/chat_messages_table.dart';
import '../../../core/error/exceptions.dart' as app_exceptions;
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import 'local_data_source.dart';

/// Drift implementation of [LocalDataSource].
///
/// Translates between [ChatMessageModel]/[ConversationModel] data objects
/// and the underlying SQLite tables managed by [AppDatabase].
class DriftLocalDataSource implements LocalDataSource {
  DriftLocalDataSource({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------------

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final rows = await (_db.select(_db.conversations)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
      return rows.map(ConversationModel.fromDrift).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(e.toString());
    }
  }

  @override
  Future<ConversationModel> createConversation(String title) async {
    try {
      final id = await _db.into(_db.conversations).insert(
            ConversationsCompanion.insert(title: title),
          );
      final row = await (_db.select(_db.conversations)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      return ConversationModel.fromDrift(row);
    } catch (e) {
      throw app_exceptions.DatabaseException(e.toString());
    }
  }

  @override
  Future<void> updateConversationTitle(int id, String title) async {
    try {
      await (_db.update(_db.conversations)..where((t) => t.id.equals(id)))
          .write(ConversationsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),);

    } catch (e) {
      throw app_exceptions.DatabaseException(e.toString());
    }
  }

  @override
  Future<void> deleteConversation(int id) async {
    try {
      // Delete messages first (cascade), then the conversation.
      await (_db.delete(_db.chatMessages)
            ..where((t) => t.conversationId.equals(id)))
          .go();
      await (_db.delete(_db.conversations)..where((t) => t.id.equals(id)))
          .go();
    } catch (e) {
      throw app_exceptions.DatabaseException(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  @override
  Future<List<ChatMessageModel>> getMessages(int conversationId) async {
    try {
      final rows = await (_db.select(_db.chatMessages)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
      return rows.map(ChatMessageModel.fromDrift).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(e.toString());
    }
  }

  @override
  Future<ChatMessageModel> insertMessage(ChatMessageModel message) async {
    try {
      final id = await _db.into(_db.chatMessages).insert(
            ChatMessagesCompanion.insert(
              conversationId: message.conversationId,
              role: MessageRole.values.byName(message.role),
              messageType: Value(MessageType.values.byName(message.messageType)),
              content: message.content,
              imagePath: Value(message.imagePath),
            ),
          );
      final row = await (_db.select(_db.chatMessages)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      // Also touch the conversation's updatedAt timestamp.
      await (_db.update(_db.conversations)
            ..where((t) => t.id.equals(message.conversationId)))
          .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));

      return ChatMessageModel.fromDrift(row);
    } catch (e) {
      throw app_exceptions.DatabaseException(e.toString());
    }
  }
}
