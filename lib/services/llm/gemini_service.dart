import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../models/chat_message.dart';
import 'llm_service.dart';

class GeminiService implements LLMService {
  late GenerativeModel _model;
  String? _apiKey;

  void _ensureInitialized() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key de Gemini no configurada');
    }
  }

  void configure(String apiKey) {
    _apiKey = apiKey;
  }

  @override
  Future<LLMResponse> sendMessage({
    required String systemPrompt,
    required List<ChatMessage> messages,
    required String model,
    List<Map<String, dynamic>> tools = const [],
    bool isPlanningMode = false,
    StreamController<String>? streamController,
  }) async {
    _ensureInitialized();

    _model = GenerativeModel(
      model: model,
      apiKey: _apiKey!,
      systemInstruction: Content.system(systemPrompt),
      tools: tools.isNotEmpty
          ? [Tool(functionDeclarations: tools.map(_parseTool).toList())]
          : null,
    );

    final chat = _model.startChat(history: _buildHistory(messages));

    final response = streamController != null
        ? await _streamResponse(chat, messages, streamController)
        : await chat.sendMessage(_buildUserContent(messages));

    final toolCalls = <Map<String, dynamic>>[];
    for (final part in response.content?.parts ?? []) {
      if (part is FunctionCall) {
        toolCalls.add({
          'name': part.name,
          'args': part.args,
        });
      }
    }

    return LLMResponse(
      content: response.text ?? '',
      toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
    );
  }

  Future<GenerateContentResponse> _streamResponse(
    ChatSession chat,
    List<ChatMessage> messages,
    StreamController<String> streamController,
  ) async {
    final response = chat.sendMessageStream(_buildUserContent(messages));
    StringBuffer buffer = StringBuffer();
    GenerateContentResponse? finalResponse;

    await for (final chunk in response) {
      buffer.write(chunk.text ?? '');
      streamController.add(chunk.text ?? '');
      if (chunk.content != null) {
        finalResponse = chunk;
      }
    }

    await streamController.close();
    return finalResponse!;
  }

  @override
  Future<LLMResponse> sendToolResults({
    required String systemPrompt,
    required List<ChatMessage> messages,
    required String model,
    required Map<String, dynamic> toolResult,
  }) async {
    _ensureInitialized();

    _model = GenerativeModel(
      model: model,
      apiKey: _apiKey!,
      systemInstruction: Content.system(systemPrompt),
    );

    final chat = _model.startChat(history: _buildHistory(messages));

    final response = await chat.sendMessage(
      Content.multi([
        ...[
          for (final entry in (toolResult['toolResults'] as List<dynamic>?) ?? [])
            if (entry is Map<String, dynamic>)
              FunctionResponsePart(
                entry['name'] as String,
                entry['response'] as Map<String, dynamic>,
              ),
        ],
      ]),
    );

    return LLMResponse(content: response.text ?? '');
  }

  @override
  String get providerName => 'gemini';

  List<Content> _buildHistory(List<ChatMessage> messages) {
    final history = <Content>[];
    for (final msg in messages) {
      if (msg.role == MessageRole.assistant) {
        history.add(Content.model([TextPart(msg.content)]));
      } else if (msg.role == MessageRole.user) {
        history.add(Content.user([TextPart(msg.content)]));
      }
    }
    return history;
  }

  Content _buildUserContent(List<ChatMessage> messages) {
    final lastUser = messages.lastWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => const ChatMessage(
        id: '',
        threadId: '',
        role: MessageRole.user,
        content: '',
        timestamp: null,
      ),
    );
    return Content.user([TextPart(lastUser.content)]);
  }

  FunctionDeclaration _parseTool(Map<String, dynamic> tool) {
    return FunctionDeclaration(
      tool['name'] as String,
      tool['description'] as String? ?? '',
      Schema(
        SchemaType.object,
        properties: (tool['parameters'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(
                      k,
                      Schema(
                        _schemaTypeFromString(v['type'] as String? ?? 'string'),
                        description: v['description'] as String?,
                      ),
                    )) ??
            {},
        requiredProperties: (tool['parameters'] as Map<String, dynamic>?)
                ?.entries
                .where((e) => e.value['required'] == true)
                .map((e) => e.key)
                .toList() ??
            [],
      ),
    );
  }

  SchemaType _schemaTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'string':
        return SchemaType.string;
      case 'integer':
      case 'number':
        return SchemaType.integer;
      case 'boolean':
        return SchemaType.boolean;
      case 'array':
        return SchemaType.array;
      case 'object':
        return SchemaType.object;
      default:
        return SchemaType.string;
    }
  }

  @override
  void dispose() {}
}
