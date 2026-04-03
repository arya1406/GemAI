import 'package:drift/drift.dart';

import 'conversations_table.dart';

/// Role of a chat participant.
enum MessageRole { user, model }

/// Drift table for storing individual chat messages.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(Conversations, #id)();
  TextColumn get role => textEnum<MessageRole>()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
