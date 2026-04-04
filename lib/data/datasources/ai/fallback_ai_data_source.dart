import '../../../core/error/exceptions.dart';
import '../../models/chat_message_model.dart';
import 'ai_data_source.dart';
import 'local_gemma_data_source.dart';

/// AI data source that prefers on-device Gemma inference and falls back
/// to an online provider (e.g. Gemini API) when the local model is
/// unavailable.
///
/// This ensures the privacy-first promise is upheld whenever possible:
/// data only leaves the device if the user has explicitly enabled online
/// fallback **and** the local model cannot serve the request.
class FallbackAiDataSource implements AiDataSource {
  FallbackAiDataSource({
    required LocalGemmaDataSource localDataSource,
    required AiDataSource onlineDataSource,
    this.allowOnlineFallback = false,
  })  : _local = localDataSource,
        _online = onlineDataSource;

  final LocalGemmaDataSource _local;
  final AiDataSource _online;

  /// When `true`, the service will try the online provider if local
  /// inference fails. Controlled by the user in Settings.
  bool allowOnlineFallback;

  @override
  Future<ChatMessageModel> sendMessage(
    List<ChatMessageModel> messages,
  ) async {
    // Attempt local inference first.
    if (_local.isReady) {
      try {
        return await _local.sendMessage(messages);
      } on AiException {
        // Local inference failed — fall through to online if allowed.
      }
    }

    if (!allowOnlineFallback) {
      throw const AiException(
        'The local AI model is not available and online fallback is '
        'disabled. Please download a Gemma model in Settings.',
      );
    }

    return _online.sendMessage(messages);
  }
}
