import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/chat_message.dart';
import 'llm_service.dart';

class OpenAIService implements LLMService {
  String? _apiKey;

  void configure(String apiKey) {
    _apiKey = apiKey;
  }

  Map<String, dynamic> _buildMessage(ChatMessage msg) {
    return {
      'role': msg.role == MessageRole.assistant ? 'assistant' : 'user',
      'content': msg.content,
    };
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
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key de OpenAI no configurada');
    }

    final body = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages.map(_buildMessage),
      ],
      if (tools.isNotEmpty) 'tools': tools.map(_formatTool).toList(),
      if (tools.isNotEmpty) 'tool_choice': 'auto',
    };

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choice = (data['choices'] as List).first as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;

    final toolCalls = <Map<String, dynamic>>[];
    if (message['tool_calls'] != null) {
      for (final tc in message['tool_calls'] as List) {
        toolCalls.add({
          'id': tc['id'],
          'name': tc['function']['name'],
          'args': jsonDecode(tc['function']['arguments']),
        });
      }
    }

    return LLMResponse(
      content: message['content'] as String? ?? '',
      toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
    );
  }

  @override
  Future<LLMResponse> sendToolResults({
    required String systemPrompt,
    required List<ChatMessage> messages,
    required String model,
    required Map<String, dynamic> toolResult,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key de OpenAI no configurada');
    }

    final body = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages.map(_buildMessage),
        {
          'role': 'tool',
          'tool_call_id': toolResult['toolCallId'],
          'content': jsonEncode(toolResult['result']),
        },
      ],
    };

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choice = (data['choices'] as List).first as Map<String, dynamic>;
    final msg = choice['message'] as Map<String, dynamic>;

    return LLMResponse(content: msg['content'] as String? ?? '');
  }

  Map<String, dynamic> _formatTool(Map<String, dynamic> tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool['name'],
        'description': tool['description'],
        'parameters': {
          'type': 'object',
          'properties': tool['parameters'],
          'required': (tool['parameters'] as Map<String, dynamic>)
              .entries
              .where((e) => e.value['required'] == true)
              .map((e) => e.key)
              .toList(),
        },
      },
    };
  }

  @override
  String get providerName => 'openai';

  @override
  void dispose() {}
}
