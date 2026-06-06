enum LLMProvider {
  gemini,
  openai,
  claude;

  String get displayName {
    switch (this) {
      case LLMProvider.gemini:
        return 'Google Gemini';
      case LLMProvider.openai:
        return 'OpenAI';
      case LLMProvider.claude:
        return 'Anthropic Claude';
    }
  }

  String get defaultModel {
    switch (this) {
      case LLMProvider.gemini:
        return 'gemini-1.5-flash';
      case LLMProvider.openai:
        return 'gpt-4o-mini';
      case LLMProvider.claude:
        return 'claude-3-5-sonnet-20241022';
    }
  }
}
