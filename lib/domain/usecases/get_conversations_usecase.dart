import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Use case: retrieve all conversations.
class GetConversationsUseCase {
  const GetConversationsUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<Conversation>> call() => _repository.getConversations();
}
