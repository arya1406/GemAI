import '../../core/database/app_database.dart';

/// Data model representing a single chat message record.
///
/// Maps between the Drift row ([ChatMessage]) and the domain layer.
/// Supports text, image, and voice message types.
class ChatMessageModel {
  const ChatMessageModel({
    this.id,
    required this.conversationId,
    required this.role,
    this.messageType = 'text',
    required this.content,
    this.imagePath,
    required this.createdAt,
  });

  /// Constructs a [ChatMessageModel] from a Drift database row.
  factory ChatMessageModel.fromDrift(ChatMessage row) {
    return ChatMessageModel(
      id: row.id,
      conversationId: row.conversationId,
      role: row.role.name,
      messageType: row.messageType.name,
      content: row.content,
      imagePath: row.imagePath,
      createdAt: row.createdAt,
    );
  }

  /// Database primary key, `null` for unsaved messages.
  final int? id;

  /// The conversation this message belongs to.
  final int conversationId;

  /// Either `'user'` or `'model'`.
  final String role;

  /// One of `'text'`, `'image'`, or `'voice'`.
  final String messageType;

  /// The textual body of the message.
  final String content;

  /// Optional local file path for an attached image.
  final String? imagePath;

  /// When this message was created.
  final DateTime createdAt;
}
