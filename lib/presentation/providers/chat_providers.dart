import 'package:flutter_riverpod/flutter_riverpod.dart';

// Hide Drift-generated classes that collide with domain entity names.
import '../../core/database/app_database.dart' hide ChatMessage, Conversation;
import '../../data/datasources/ai/fallback_ai_data_source.dart';
import '../../data/datasources/ai/gemini_data_source.dart';
import '../../data/datasources/ai/local_gemma_data_source.dart';
import '../../data/datasources/local/drift_local_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'settings_providers.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

/// Holds a [LocalGemmaDataSource] that was pre-loaded from bundled assets
/// during app startup. Overridden in the root [ProviderScope] when the
/// bundled model was installed and loaded successfully.
final preloadedGemmaProvider = Provider<LocalGemmaDataSource?>((ref) => null);

/// Provides the on-device Gemma data source, configured with the
/// user's selected model variant from Settings.
///
/// If a preloaded instance exists (bundled model loaded at startup)
/// and matches the current variant, it is reused so the model does
/// not need to be loaded again.
final localGemmaDataSourceProvider = Provider<LocalGemmaDataSource>((ref) {
  final variant = ref.watch(modelVariantProvider);
  final preloaded = ref.watch(preloadedGemmaProvider);
  if (preloaded != null && preloaded.variant == variant && preloaded.isReady) {
    return preloaded;
  }
  return LocalGemmaDataSource(variant: variant);
});

/// Provides the online Gemini fallback data source.
///
/// The API key is injected at compile-time via `--dart-define`.
final geminiDataSourceProvider = Provider<GeminiDataSource>((ref) {
  return GeminiDataSource.fromApiKey(
    const String.fromEnvironment('GEMINI_API_KEY'),
  );
});

/// Provides the [FallbackAiDataSource] that tries local Gemma first.
/// Online fallback is disabled — all inference stays on-device.
final aiDataSourceProvider = Provider<FallbackAiDataSource>((ref) {
  return FallbackAiDataSource(
    localDataSource: ref.watch(localGemmaDataSourceProvider),
    onlineDataSource: ref.watch(geminiDataSourceProvider),
    allowOnlineFallback: false,
  );
});

/// Provides the Drift-backed local data source.
final localDataSourceProvider = Provider<DriftLocalDataSource>((ref) {
  return DriftLocalDataSource(database: ref.watch(appDatabaseProvider));
});

/// Provides the [ChatRepository] wired to both AI and local sources.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    aiDataSource: ref.watch(aiDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

/// Provides the [GetConversationsUseCase].
final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>(
  (ref) => GetConversationsUseCase(ref.watch(chatRepositoryProvider)),
);

/// Provides the [GetMessagesUseCase].
final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>(
  (ref) => GetMessagesUseCase(ref.watch(chatRepositoryProvider)),
);

/// Provides the [SendMessageUseCase].
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(ref.watch(chatRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// State providers
// ---------------------------------------------------------------------------

/// Async provider that loads the list of all conversations.
final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  return ref.watch(getConversationsUseCaseProvider).call();
});

/// Provides all persisted messages for a given conversation.
///
/// Auto-disposes when the screen is no longer active.
/// Call `ref.invalidate(chatMessagesProvider(id))` after mutations
/// to trigger a reload.
final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, int>((ref, conversationId) {
  return ref.watch(getMessagesUseCaseProvider).call(conversationId);
});
