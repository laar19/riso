import '../../models/chat_message.dart';
import 'dart:async';

class LLMResponse {
  final String content;
  final List<Map<String, dynamic>>? toolCalls;

  const LLMResponse({required this.content, this.toolCalls});
}

abstract class LLMService {
  Future<LLMResponse> sendMessage({
    required String systemPrompt,
    required List<ChatMessage> messages,
    required String model,
    List<Map<String, dynamic>> tools = const [],
    bool isPlanningMode = false,
    StreamController<String>? streamController,
  });

  Future<LLMResponse> sendToolResults({
    required String systemPrompt,
    required List<ChatMessage> messages,
    required String model,
    required Map<String, dynamic> toolResult,
  });

  String get providerName;

  void dispose();
}
