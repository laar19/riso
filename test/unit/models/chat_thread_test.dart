import 'package:flutter_test/flutter_test.dart';
import 'package:riso/models/chat_thread.dart';
import 'package:riso/models/llm_provider.dart';

void main() {
  group('ChatThread', () {
    test('toJson y fromJson preservan todos los campos', () {
      final original = ChatThread(
        id: 'thread-1',
        title: 'Mi chat',
        provider: LLMProvider.gemini,
        model: 'gemini-1.5-flash',
        createdAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 2),
        messageCount: 5,
      );

      final json = original.toJson();
      final restored = ChatThread.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.provider, original.provider);
      expect(restored.model, original.model);
      expect(restored.messageCount, original.messageCount);
    });

    test('copyWith actualiza solo los campos especificados', () {
      final thread = ChatThread(
        id: 't1',
        title: 'original',
        provider: LLMProvider.gemini,
        model: 'gemini-1.5-flash',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final updated = thread.copyWith(
        title: 'modificado',
        messageCount: 3,
        provider: LLMProvider.openai,
      );

      expect(updated.title, 'modificado');
      expect(updated.messageCount, 3);
      expect(updated.provider, LLMProvider.openai);
      expect(updated.id, 't1');
      expect(updated.model, 'gemini-1.5-flash');
    });

    test('fromJson usa valores por defecto para campos opcionales', () {
      final json = {
        'id': 't1',
        'title': 'test',
        'provider': 'claude',
        'model': 'claude-3-5-sonnet-20241022',
        'createdAt': '2025-01-01T00:00:00.000',
        'updatedAt': '2025-01-01T00:00:00.000',
      };

      final thread = ChatThread.fromJson(json);
      expect(thread.messageCount, 0);
    });
  });
}
