import '../../models/llm_provider.dart';
import 'llm_service.dart';
import 'gemini_service.dart';
import 'openai_service.dart';
import 'claude_service.dart';

class LLMResolver {
  final GeminiService _gemini;
  final OpenAIService _openai;
  final ClaudeService _claude;

  LLMResolver({
    required GeminiService gemini,
    required OpenAIService openai,
    required ClaudeService claude,
  })  : _gemini = gemini,
        _openai = openai,
        _claude = claude;

  LLMService resolve(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.gemini:
        return _gemini;
      case LLMProvider.openai:
        return _openai;
      case LLMProvider.claude:
        return _claude;
    }
  }

  void configureAll(Map<String, String?> keys) {
    if (keys['gemini'] != null) _gemini.configure(keys['gemini']!);
    if (keys['openai'] != null) _openai.configure(keys['openai']!);
    if (keys['claude'] != null) _claude.configure(keys['claude']!);
  }
}
