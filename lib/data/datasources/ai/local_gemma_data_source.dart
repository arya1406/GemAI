import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/error/exceptions.dart';
import '../../models/chat_message_model.dart';
import 'ai_data_source.dart';

/// Supported Gemma model variants, ordered by resource requirements.
///
/// Users select a variant in Settings based on their device capabilities.
/// Each variant maps to a public HuggingFace URL for runtime download.
///
/// **Important:** URLs point to the `litert-community` organization which
/// hosts public (ungated) models. The official `google/` repos require
/// HuggingFace authentication and will return HTTP 401 if accessed without
/// a token.
enum GemmaModelVariant {
  /// Smallest footprint — suitable for low-RAM devices (≤ 4 GB).
  /// Uses Gemma 3 1B (instruction-tuned, int4 quantized).
  ultraLight(
    'gemma3-1b-it-int4',
    'Ultra-Light (1B)',
    'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
    assetPath: 'assets/models/gemma3-1b-it-int4.task',
  ),

  /// Default variant — balanced performance for most smartphones.
  /// Uses Gemma 4 E2B (instruction-tuned, ~2.3B effective parameters).
  standard(
    'gemma-4-E2B-it-web',
    'Standard — Gemma 4 E2B',
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it-web.task',
  ),

  /// Highest quality — requires devices with ≥ 8 GB RAM.
  /// Uses Gemma 4 E4B (instruction-tuned, ~4.5B effective parameters).
  full(
    'gemma-4-E4B-it-web',
    'Full — Gemma 4 E4B',
    'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it-web.task',
  );

  const GemmaModelVariant(
    this.modelFileName,
    this.displayName,
    this.downloadUrl, {
    this.assetPath,
  });

  /// File name of the model asset (without extension).
  final String modelFileName;

  /// Human-readable label shown in the settings UI.
  final String displayName;

  /// HuggingFace URL to download the model from.
  final String downloadUrl;

  /// Flutter asset path for a model bundled inside the APK/IPA.
  /// When non-null the model can be installed from local assets
  /// instead of downloading from the network.
  final String? assetPath;

  /// Whether this variant ships inside the app bundle.
  bool get isBundled => assetPath != null;
}

/// On-device Gemma 4 inference via `flutter_gemma` (MediaPipe GenAI).
///
/// This data source runs the model entirely on the user's device, ensuring
/// that no data ever leaves the phone. It uses [FlutterGemma] to install
/// models and create chat sessions for local inference.
class LocalGemmaDataSource implements AiDataSource {
  LocalGemmaDataSource({
    this.variant = GemmaModelVariant.standard,
  });

  /// The currently selected model variant.
  GemmaModelVariant variant;

  /// Whether the local model has been successfully loaded.
  bool _isModelLoaded = false;

  /// The active Gemma model instance, available after [loadModel].
  InferenceModel? _model;

  /// Attempts to install and load the on-device model for the selected
  /// [variant].
  ///
  /// If the model is not cached, downloads it from HuggingFace and reports
  /// progress to [onProgress] (0.0 to 1.0).
  /// Then creates an [InferenceModel] instance for generation.
  /// Returns `true` on success.
  /// Installs a bundled model from Flutter assets.
  ///
  /// Only works for variants where [GemmaModelVariant.isBundled] is true.
  /// The file is copied from the APK/IPA into the device's data directory.
  /// Subsequent calls are no-ops if the file already exists.
  /// Returns `true` on success.
  Future<bool> installFromAsset() async {
    if (variant.assetPath == null) return false;
    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromAsset(variant.assetPath!).install();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Downloads the model file for the selected [variant].
  ///
  /// Returns `true` if the download completes successfully.
  /// Model loading is attempted separately via [loadModel].
  Future<bool> downloadModel({
    void Function(double)? onProgress,
  }) async {
    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromNetwork(variant.downloadUrl).withProgress((progress) {
        if (onProgress != null) {
          onProgress(progress / 100.0);
        }
      }).install();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Attempts to load the previously downloaded model into memory.
  ///
  /// Returns `true` on success. If loading fails (e.g. incompatible format),
  /// falls back to CPU backend before giving up.
  Future<bool> loadModel() async {
    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.gpu,
      );
      _isModelLoaded = true;
      return true;
    } catch (_) {
      // GPU backend may not support this model — try CPU fallback.
      try {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 1024,
          preferredBackend: PreferredBackend.cpu,
        );
        _isModelLoaded = true;
        return true;
      } catch (e) {
        _isModelLoaded = false;
        _model = null;
        return false;
      }
    }
  }

  /// Downloads and then loads the model. Convenience wrapper.
  Future<bool> downloadAndLoadModel({
    void Function(double)? onProgress,
  }) async {
    final downloaded = await downloadModel(onProgress: onProgress);
    if (!downloaded) return false;
    return loadModel();
  }

  /// Whether the local model is ready to accept prompts.
  bool get isReady => _isModelLoaded;

  @override
  Future<ChatMessageModel> sendMessage(
    List<ChatMessageModel> messages,
  ) async {
    if (!_isModelLoaded || _model == null) {
      throw const AiException(
        'Local Gemma model is not loaded. '
        'Please download a model in Settings or switch to online mode.',
      );
    }

    try {
      // Create a new chat session.
      final chat = await _model!.createChat();

      // Add conversation history (all messages except the last).
      for (final message in messages.take(messages.length - 1)) {
        await chat.addQueryChunk(
          Message.text(
            text: message.content,
            isUser: message.role == 'user',
          ),
        );
      }

      // Add the latest user query.
      final lastMessage = messages.last;
      await chat.addQueryChunk(
        Message.text(
          text: lastMessage.content,
          isUser: true,
        ),
      );

      // Generate a response.
      final responseObj = await chat.generateChatResponse();
      final text = responseObj is TextResponse ? responseObj.token.trim() : '';

      if (text.isEmpty) {
        throw const AiException('Empty response from local Gemma model.');
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
      throw AiException('Local inference error: $e');
    }
  }

  /// Releases model resources. Call when the data source is no longer
  /// needed or before switching model variants.
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    _isModelLoaded = false;
  }
}
