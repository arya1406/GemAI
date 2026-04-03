import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/app_database.dart';
import '../../data/datasources/ai/gemini_data_source.dart';
import '../../data/datasources/local/drift_local_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

part 'chat_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final generativeModelProvider = Provider<GenerativeModel>((ref) {
  // TODO(dev): replace with a secure secret manager / env variable.
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  return GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
});

final aiDataSourceProvider = Provider<GeminiDataSource>((ref) {
  return GeminiDataSource(model: ref.watch(generativeModelProvider));
});

final localDataSourceProvider = Provider<DriftLocalDataSource>((ref) {
  return DriftLocalDataSource(database: ref.watch(appDatabaseProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    aiDataSource: ref.watch(aiDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>(
  (ref) => GetConversationsUseCase(ref.watch(chatRepositoryProvider)),
);

final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>(
  (ref) => GetMessagesUseCase(ref.watch(chatRepositoryProvider)),
);

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(ref.watch(chatRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// State providers
// ---------------------------------------------------------------------------

@riverpod
Future<List<Conversation>> conversations(Ref ref) =>
    ref.watch(getConversationsUseCaseProvider).call();

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  FutureOr<List<ChatMessage>> build(int conversationId) =>
      ref.watch(getMessagesUseCaseProvider).call(conversationId);

  Future<void> sendMessage(String content) async {
    final sendUseCase = ref.read(sendMessageUseCaseProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        await sendUseCase(
          conversationId: conversationId,
          content: content,
        );
        return ref.read(getMessagesUseCaseProvider).call(conversationId);
      },
    );
  }
}
