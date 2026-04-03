import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Use case: send a user message and receive the AI reply.
class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<ChatMessage> call({
    required int conversationId,
    required String content,
  }) =>
      _repository.sendMessage(
        conversationId: conversationId,
        content: content,
      );
}
