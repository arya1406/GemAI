import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/ai/ai_data_source.dart';
import '../datasources/local/local_data_source.dart';
import '../models/chat_message_model.dart';

/// Implementation of [ChatRepository] using AI and local data sources.
///
/// Orchestrates message persistence via [LocalDataSource] and AI inference
/// via [AiDataSource]. Supports text and image-based messages.
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
    return models.map(_toConversation).toList();
  }

  @override
  Future<Conversation> createConversation(String title) async {
    final model = await _local.createConversation(title);
    return _toConversation(model);
  }

  @override
  Future<void> updateConversationTitle(int id, String title) =>
      _local.updateConversationTitle(id, title);

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
    String? imagePath,
  }) async {
    final history = await _local.getMessages(conversationId);

    // Determine message type based on attachment.
    final messageType = imagePath != null ? 'image' : 'text';

    final userModel = await _local.insertMessage(
      ChatMessageModel(
        conversationId: conversationId,
        role: 'user',
        messageType: messageType,
        content: content,
        imagePath: imagePath,
        createdAt: DateTime.now(),
      ),
    );

    final allMessages = [...history, userModel];
    final aiResponseModel = await _ai.sendMessage(allMessages);

    final savedAiModel = await _local.insertMessage(aiResponseModel);
    return _toChatMessage(savedAiModel);
  }

  Conversation _toConversation(dynamic m) => Conversation(
        id: m.id,
        title: m.title,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      );

  ChatMessage _toChatMessage(ChatMessageModel m) => ChatMessage(
        id: m.id,
        conversationId: m.conversationId,
        role: m.role,
        messageType: m.messageType,
        content: m.content,
        imagePath: m.imagePath,
        createdAt: m.createdAt,
      );
}
