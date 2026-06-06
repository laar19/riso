import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../models/llm_provider.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/llm_resolver.dart';
import '../services/llm/function_calling_handler.dart';
import '../services/llm/function_calling_tools.dart';
import '../services/llm/prompts.dart';
import '../services/llm/rate_limiter.dart';
import '../services/storage/database_service.dart';
import 'service_providers.dart';
import 'planning_mode_provider.dart';
import 'email_provider.dart';
import 'settings_provider.dart';

class ChatState {
  final List<ChatThread> threads;
  final ChatThread? currentThread;
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isStreaming;
  final String streamingContent;

  const ChatState({
    this.threads = const [],
    this.currentThread,
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isStreaming = false,
    this.streamingContent = '',
  });

  ChatState copyWith({
    List<ChatThread>? threads,
    ChatThread? currentThread,
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isStreaming,
    String? streamingContent,
  }) {
    return ChatState(
      threads: threads ?? this.threads,
      currentThread: currentThread ?? this.currentThread,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingContent: streamingContent ?? this.streamingContent,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final DatabaseService _db;
  final LLMResolver _resolver;
  final FunctionCallingHandler _functionHandler;
  final RateLimiter _rateLimiter;
  final Ref _ref;

  ChatNotifier(
    this._db,
    this._resolver,
    this._functionHandler,
    this._rateLimiter,
    this._ref,
  ) : super(const ChatState()) {
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final threads = await _db.getAllThreads();
    state = state.copyWith(threads: threads);
  }

  Future<void> createThread({
    required LLMProvider provider,
    String? title,
    String model = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final thread = ChatThread(
      id: id,
      title: title ?? 'Nuevo chat',
      provider: provider,
      model: model.isEmpty ? provider.defaultModel : model,
      createdAt: now,
      updatedAt: now,
    );

    await _db.saveThread(thread);
    state = state.copyWith(
      threads: [thread, ...state.threads],
      currentThread: thread,
      messages: [],
    );
  }

  Future<void> selectThread(ChatThread thread) async {
    final messages = await _db.getMessages(thread.id);
    state = state.copyWith(
      currentThread: thread,
      messages: messages,
    );
  }

  Future<void> deleteThread(String id) async {
    await _db.deleteThread(id);
    if (state.currentThread?.id == id) {
      state = state.copyWith(currentThread: null, messages: []);
    }
    await _loadThreads();
  }

  Future<void> sendMessage(String content) async {
    if (state.currentThread == null || content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      threadId: state.currentThread!.id,
      role: MessageRole.user,
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    await _db.saveMessage(userMessage);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      isStreaming: true,
      streamingContent: '',
      error: null,
    );

    try {
      final isPlanning = _ref.read(planningModeProvider);

      await _rateLimiter.waitIfNeeded(
        estimatedTokens: content.length ~/ 2,
      );

      final emailState = _ref.read(emailProvider);
      final settings = _ref.read(settingsProvider);

      final llm = _resolver.resolve(state.currentThread!.provider);
      final prompt = systemPromptTemplate(
        isPlanningMode: isPlanning,
        emailState: emailState,
        settingsState: settings,
      );
      final allMessages = [...state.messages, userMessage];

      final streamCtrl = StreamController<String>();
      final responseFut = llm.sendMessage(
        systemPrompt: prompt,
        messages: allMessages,
        model: state.currentThread!.model,
        tools: emailTools,
        isPlanningMode: isPlanning,
        streamController: streamCtrl,
      );

      streamCtrl.stream.listen(
        (chunk) {
          if (mounted) {
            state = state.copyWith(
              streamingContent: state.streamingContent + chunk,
            );
          }
        },
        onDone: () {
          if (mounted) {
            state = state.copyWith(isStreaming: false);
          }
        },
        onError: (e) {
          if (mounted) {
            state = state.copyWith(
              isStreaming: false,
              error: e.toString(),
            );
          }
        },
      );

      final result = await responseFut;

      String finalContent = result.content;

      if (result.toolCalls != null && result.toolCalls!.isNotEmpty) {
        for (final toolCall in result.toolCalls!) {
          final functionResult = await _functionHandler.handleToolCall(
            toolCall['name'] as String,
            toolCall['args'] as Map<String, dynamic>,
          );

          if (isPlanning && functionResult.isWriteOperation) {
            finalContent +=
                '\n\n⛔ **Operación bloqueada por Modo Planificación**\n'
                'La IA solicitó: ${functionResult.description}\n'
                'Desactiva el Modo Planificación para ejecutar esta acción.';
            continue;
          }

          final toolResultMsg = ChatMessage(
            id: const Uuid().v4(),
            threadId: state.currentThread!.id,
            role: MessageRole.assistant,
            content: 'Herramienta ejecutada: ${toolCall['name']}\n'
                'Resultado: ${functionResult.description}',
            timestamp: DateTime.now(),
            toolResults: {
              'toolResults': [
                {
                  'name': toolCall['name'],
                  'response': functionResult.result,
                }
              ],
            },
          );
          await _db.saveMessage(toolResultMsg);
        }
      }

      final assistantMsg = ChatMessage(
        id: const Uuid().v4(),
        threadId: state.currentThread!.id,
        role: MessageRole.assistant,
        content: finalContent,
        timestamp: DateTime.now(),
        modelUsed: state.currentThread!.model,
      );

      await _db.saveMessage(assistantMsg);
      final updatedThread = state.currentThread!.copyWith(
        messageCount: state.messages.length + 2,
        updatedAt: DateTime.now(),
      );
      await _db.saveThread(updatedThread);

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        currentThread: updatedThread,
        isLoading: false,
        isStreaming: false,
        streamingContent: '',
      );
    } on RateLimitExceeded catch (e) {
      state = state.copyWith(
        isLoading: false,
        isStreaming: false,
        streamingContent: '',
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isStreaming: false,
        streamingContent: '',
        error: e.toString(),
      );
    }

    await _loadThreads();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.watch(databaseServiceProvider),
    ref.watch(llmResolverProvider),
    ref.watch(functionCallingHandlerProvider),
    RateLimiter(),
    ref,
  );
});
