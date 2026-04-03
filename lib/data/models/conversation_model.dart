import '../../core/database/app_database.dart';

/// Data model representing a conversation record.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromDrift(Conversation row) {
    return ConversationModel(
      id: row.id,
      title: row.title,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
}
