import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/chat_message.dart';
import 'llm_service.dart';

class ClaudeService implements LLMService {
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
      throw Exception('API key de Claude no configurada');
    }

    final body = {
      'model': model,
      'system': systemPrompt,
      'messages': messages.map(_buildMessage).toList(),
      'max_tokens': 4096,
      if (tools.isNotEmpty) 'tools': tools.map(_formatTool).toList(),
    };

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _apiKey!,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Claude API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;

    final textParts = <String>[];
    final toolCalls = <Map<String, dynamic>>[];

    for (final block in content) {
      if (block['type'] == 'text') {
        textParts.add(block['text'] as String);
      } else if (block['type'] == 'tool_use') {
        toolCalls.add({
          'id': block['id'],
          'name': block['name'],
          'args': block['input'],
        });
      }
    }

    return LLMResponse(
      content: textParts.join('\n'),
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
      throw Exception('API key de Claude no configurada');
    }

    final body = {
      'model': model,
      'system': systemPrompt,
      'messages': [
        ...messages.map(_buildMessage),
        {
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': toolResult['toolCallId'],
              'content': jsonEncode(toolResult['result']),
            }
          ],
        },
      ],
      'max_tokens': 4096,
    };

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _apiKey!,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    final textParts = content
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String);

    return LLMResponse(content: textParts.join('\n'));
  }

  Map<String, dynamic> _formatTool(Map<String, dynamic> tool) {
    return {
      'name': tool['name'],
      'description': tool['description'],
      'input_schema': {
        'type': 'object',
        'properties': tool['parameters'],
        'required': (tool['parameters'] as Map<String, dynamic>)
            .entries
            .where((e) => e.value['required'] == true)
            .map((e) => e.key)
            .toList(),
      },
    };
  }

  @override
  String get providerName => 'claude';

  @override
  void dispose() {}
}
