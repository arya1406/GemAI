import '../../models/chat_message_model.dart';

/// Contract for the AI remote data source.
abstract interface class AiDataSource {
  /// Sends [messages] to the AI and returns the model's reply.
  Future<ChatMessageModel> sendMessage(List<ChatMessageModel> messages);
}
