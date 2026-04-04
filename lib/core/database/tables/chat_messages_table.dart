import 'package:drift/drift.dart';

import 'conversations_table.dart';

/// Role of a chat participant.
enum MessageRole { user, model }

/// The type of content carried by a message.
enum MessageType { text, image, voice }

/// Drift table for storing individual chat messages.
///
/// Each message belongs to a [Conversations] row via [conversationId].
/// Messages can carry text, an image path, or both (e.g. an image with
/// a user caption or an AI description).
class ChatMessages extends Table {
  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key referencing [Conversations.id].
  IntColumn get conversationId =>
      integer().references(Conversations, #id)();

  /// Whether this message was sent by the [MessageRole.user] or [MessageRole.model].
  TextColumn get role => textEnum<MessageRole>()();

  /// The kind of content this message carries.
  TextColumn get messageType =>
      textEnum<MessageType>().withDefault(Constant(MessageType.text.name))();

  /// The textual body of the message. May be empty for voice-only inputs.
  TextColumn get content => text()();

  /// Optional local file path for an attached image.
  TextColumn get imagePath => text().nullable()();

  /// Timestamp when the message was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
