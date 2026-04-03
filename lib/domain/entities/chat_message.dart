/// Domain entity representing a single chat message.
class ChatMessage {
  const ChatMessage({
    this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final int? id;
  final int conversationId;

  /// Either `'user'` or `'model'`.
  final String role;
  final String content;
  final DateTime createdAt;

  bool get isFromUser => role == 'user';
}
