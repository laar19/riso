import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riso/models/chat_thread.dart';
import 'package:riso/models/chat_message.dart';
import 'package:riso/models/email_account.dart';
import 'package:riso/models/llm_provider.dart';
import 'package:riso/services/storage/database_service.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService db;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final path = '${Directory.systemTemp.path}/test_hive_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(path);

      db = DatabaseService();
      await db.init();
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk('threads');
      await Hive.deleteBoxFromDisk('messages');
      await Hive.deleteBoxFromDisk('emailAccounts');
      await Hive.deleteBoxFromDisk('riso_meta');
    });

    test('save y getAllThreads retorna threads ordenados por updatedAt', () async {
      final t1 = ChatThread(
        id: '1',
        title: 'A',
        provider: LLMProvider.gemini,
        model: 'm',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      final t2 = ChatThread(
        id: '2',
        title: 'B',
        provider: LLMProvider.gemini,
        model: 'm',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 3),
      );

      await db.saveThread(t1);
      await db.saveThread(t2);

      final threads = await db.getAllThreads();
      expect(threads.length, 2);
      expect(threads.first.id, '2');
    });

    test('deleteThread elimina thread y sus mensajes', () async {
      await db.saveThread(ChatThread(
        id: 't1',
        title: 'test',
        provider: LLMProvider.gemini,
        model: 'm',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ));
      await db.saveMessage(ChatMessage(
        id: 'm1',
        threadId: 't1',
        role: MessageRole.user,
        content: 'hola',
        timestamp: DateTime(2025, 1, 1),
      ));

      await db.deleteThread('t1');

      expect(await db.getAllThreads(), isEmpty);
      expect(await db.getMessages('t1'), isEmpty);
    });

    test('getMessages retorna ordenados por timestamp', () async {
      await db.saveMessage(ChatMessage(
        id: 'm2',
        threadId: 't1',
        role: MessageRole.user,
        content: 'segundo',
        timestamp: DateTime(2025, 1, 2),
      ));
      await db.saveMessage(ChatMessage(
        id: 'm1',
        threadId: 't1',
        role: MessageRole.user,
        content: 'primero',
        timestamp: DateTime(2025, 1, 1),
      ));

      final messages = await db.getMessages('t1');
      expect(messages.length, 2);
      expect(messages.first.content, 'primero');
    });

    test('save y getAllEmailAccounts', () async {
      await db.saveEmailAccount(EmailAccount(
        id: 'a1',
        email: 'test@test.com',
        displayName: 'Test',
        protocol: EmailProtocol.imapSmtp,
      ));

      final accounts = await db.getAllEmailAccounts();
      expect(accounts.length, 1);
      expect(accounts.first.email, 'test@test.com');
    });

    test('importThreads no duplica threads existentes', () async {
      await db.saveThread(ChatThread(
        id: 't1',
        title: 'original',
        provider: LLMProvider.gemini,
        model: 'm',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ));

      await db.importThreads([
        ChatThread(
          id: 't1',
          title: 'nuevo',
          provider: LLMProvider.gemini,
          model: 'm',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
        ChatThread(
          id: 't2',
          title: 'nuevo thread',
          provider: LLMProvider.gemini,
          model: 'm',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ]);

      final threads = await db.getAllThreads();
      expect(threads.length, 2);
      expect(threads.where((t) => t.id == 't1').first.title, 'original');
    });

    test('mensajes corruptos no rompen getMessages', () async {
      // Simular dato corrupto
      final box = await Hive.openBox<String>('messages');
      await box.put('t1:corrupto', '{json invalido');
      await box.close();

      await db.saveMessage(ChatMessage(
        id: 'm1',
        threadId: 't1',
        role: MessageRole.user,
        content: 'válido',
        timestamp: DateTime(2025, 1, 1),
      ));

      final messages = await db.getMessages('t1');
      expect(messages.length, 1);
      expect(messages.first.content, 'válido');
    });
  });
}
