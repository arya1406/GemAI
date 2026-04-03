/// Domain entity representing a conversation.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
}
