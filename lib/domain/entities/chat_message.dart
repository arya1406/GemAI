/// Domain entity representing a single chat message.
///
/// Supports text, image, and voice message types for multimodal
/// interaction with the Gemma 4 model.
class ChatMessage {
  const ChatMessage({
    this.id,
    required this.conversationId,
    required this.role,
    this.messageType = 'text',
    required this.content,
    this.imagePath,
    required this.createdAt,
  });

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

  /// Timestamp when the message was created.
  final DateTime createdAt;

  /// Whether this message was sent by the user.
  bool get isFromUser => role == 'user';

  /// Whether this message carries an image attachment.
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
}
