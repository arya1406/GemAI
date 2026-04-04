import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Use case: send a user message and receive the AI reply.
class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  /// Sends a message with [content] and optional [imagePath] in the
  /// conversation identified by [conversationId].
  Future<ChatMessage> call({
    required int conversationId,
    required String content,
    String? imagePath,
  }) =>
      _repository.sendMessage(
        conversationId: conversationId,
        content: content,
        imagePath: imagePath,
      );
}
