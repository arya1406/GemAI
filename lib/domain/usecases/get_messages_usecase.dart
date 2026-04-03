import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Use case: fetch all messages for a given conversation.
class GetMessagesUseCase {
  const GetMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<ChatMessage>> call(int conversationId) =>
      _repository.getMessages(conversationId);
}
