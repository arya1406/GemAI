import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/ai/ai_data_source.dart';
import '../datasources/local/local_data_source.dart';
import '../models/chat_message_model.dart';

/// Implementation of [ChatRepository] using AI and local data sources.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required AiDataSource aiDataSource,
    required LocalDataSource localDataSource,
  })  : _ai = aiDataSource,
        _local = localDataSource;

  final AiDataSource _ai;
  final LocalDataSource _local;

  @override
  Future<List<Conversation>> getConversations() async {
    final models = await _local.getConversations();
    return models
        .map(
          (m) => Conversation(
            id: m.id,
            title: m.title,
            createdAt: m.createdAt,
            updatedAt: m.updatedAt,
          ),
        )
        .toList();
  }

  @override
  Future<Conversation> createConversation(String title) async {
    final model = await _local.createConversation(title);
    return Conversation(
      id: model.id,
      title: model.title,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  @override
  Future<void> deleteConversation(int id) => _local.deleteConversation(id);

  @override
  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final models = await _local.getMessages(conversationId);
    return models.map(_toChatMessage).toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    final history = await _local.getMessages(conversationId);

    final userModel = await _local.insertMessage(
      ChatMessageModel(
        conversationId: conversationId,
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      ),
    );

    final allMessages = [...history, userModel];
    final aiResponseModel = await _ai.sendMessage(allMessages);

    final savedAiModel = await _local.insertMessage(aiResponseModel);
    return _toChatMessage(savedAiModel);
  }

  ChatMessage _toChatMessage(ChatMessageModel m) => ChatMessage(
        id: m.id,
        conversationId: m.conversationId,
        role: m.role,
        content: m.content,
        createdAt: m.createdAt,
      );
}
