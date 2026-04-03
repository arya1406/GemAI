import '../../core/database/app_database.dart';
import '../../core/database/tables/chat_messages_table.dart';

/// Data model representing a single chat message record.
class ChatMessageModel {
  const ChatMessageModel({
    this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessageModel.fromDrift(ChatMessage row) {
    return ChatMessageModel(
      id: row.id,
      conversationId: row.conversationId,
      role: row.role.name,
      content: row.content,
      createdAt: row.createdAt,
    );
  }

  final int? id;
  final int conversationId;
  final String role;
  final String content;
  final DateTime createdAt;
}
