import 'package:flutter_test/flutter_test.dart';
import 'package:riso/models/backup_data.dart';
import 'package:riso/models/chat_thread.dart';
import 'package:riso/models/chat_message.dart';
import 'package:riso/models/email_account.dart';
import 'package:riso/models/llm_provider.dart';

void main() {
  group('BackupData', () {
    test('toJson/fromJson preserva listas de threads y mensajes', () {
      final original = BackupData(
        appVersion: '1.0.0',
        exportedAt: DateTime(2025, 6, 1),
        threads: [
          ChatThread(
            id: 't1',
            title: 'Chat 1',
            provider: LLMProvider.gemini,
            model: 'gemini-1.5-flash',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ],
        messages: [
          ChatMessage(
            id: 'm1',
            threadId: 't1',
            role: MessageRole.user,
            content: 'hola',
            timestamp: DateTime(2025, 1, 1),
          ),
        ],
        emailAccounts: [
          EmailAccount(
            id: 'a1',
            email: 'test@gmail.com',
            displayName: 'Test',
            protocol: EmailProtocol.gmailApi,
          ),
        ],
      );

      final json = original.toJson();
      final restored = BackupData.fromJson(json);

      expect(restored.appVersion, '1.0.0');
      expect(restored.threads.length, 1);
      expect(restored.messages.length, 1);
      expect(restored.emailAccounts.length, 1);
      expect(restored.threads.first.title, 'Chat 1');
      expect(restored.emailAccounts.first.email, 'test@gmail.com');
    });

    test('fromJson tolera JSON vacío', () {
      final restored = BackupData.fromJson({});
      expect(restored.threads, isEmpty);
      expect(restored.messages, isEmpty);
      expect(restored.emailAccounts, isEmpty);
      expect(restored.appVersion, 'unknown');
    });
  });
}
