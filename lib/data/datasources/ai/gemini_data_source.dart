import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/error/exceptions.dart';
import '../../models/chat_message_model.dart';
import 'ai_data_source.dart';

/// Gemini implementation of [AiDataSource].
class GeminiDataSource implements AiDataSource {
  GeminiDataSource({required GenerativeModel model}) : _model = model;

  final GenerativeModel _model;

  @override
  Future<ChatMessageModel> sendMessage(
    List<ChatMessageModel> messages,
  ) async {
    try {
      final history = messages
          .take(messages.length - 1)
          .map(
            (m) => Content(
              m.role,
              [TextPart(m.content)],
            ),
          )
          .toList();

      final chat = _model.startChat(history: history);
      final lastMessage = messages.last;
      final response = await chat.sendMessage(
        Content.text(lastMessage.content),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const AiException('Empty response from Gemini.');
      }

      return ChatMessageModel(
        conversationId: lastMessage.conversationId,
        role: 'model',
        content: text,
        createdAt: DateTime.now(),
      );
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException(e.toString());
    }
  }
}
