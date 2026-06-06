import 'package:flutter_test/flutter_test.dart';
import 'package:riso/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('toJson y fromJson son simétricos', () {
      final original = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: MessageRole.user,
        content: 'Hola, ¿cómo estás?',
        timestamp: DateTime(2025, 6, 6, 12, 0, 0),
        modelUsed: 'gemini-1.5-flash',
      );

      final json = original.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.threadId, original.threadId);
      expect(restored.role, original.role);
      expect(restored.content, original.content);
      expect(restored.timestamp, original.timestamp);
      expect(restored.modelUsed, original.modelUsed);
    });

    test('copyWith actualiza campos', () {
      final msg = ChatMessage(
        id: '1',
        threadId: 't1',
        role: MessageRole.user,
        content: 'original',
        timestamp: DateTime(2025, 1, 1),
      );

      final copy = msg.copyWith(content: 'modificado', isStreaming: true);

      expect(copy.content, 'modificado');
      expect(copy.isStreaming, true);
      expect(copy.id, '1');
    });

    test('fromJson tolera campos faltantes con null safety', () {
      final json = {
        'id': 'msg-2',
        'threadId': 'thread-2',
        'role': 'assistant',
        'content': 'respuesta',
        'timestamp': '2025-06-01T10:00:00.000',
      };

      final msg = ChatMessage.fromJson(json);
      expect(msg.id, 'msg-2');
      expect(msg.modelUsed, null);
      expect(msg.isStreaming, false);
    });

    test('equatable funciona correctamente', () {
      final a = ChatMessage(
        id: '1',
        threadId: 't1',
        role: MessageRole.assistant,
        content: 'hola',
        timestamp: DateTime(2025, 1, 1),
      );
      final b = ChatMessage(
        id: '1',
        threadId: 't1',
        role: MessageRole.assistant,
        content: 'hola',
        timestamp: DateTime(2025, 1, 1),
      );
      final c = ChatMessage(
        id: '2',
        threadId: 't1',
        role: MessageRole.assistant,
        content: 'hola',
        timestamp: DateTime(2025, 1, 1),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('MessageRole', () {
    test('serializa correctamente a JSON', () {
      expect(MessageRole.user.name, 'user');
      expect(MessageRole.assistant.name, 'assistant');
    });

    test('deserializa desde JSON', () {
      expect(MessageRole.values.byName('user'), MessageRole.user);
      expect(MessageRole.values.byName('assistant'), MessageRole.assistant);
    });
  });
}
