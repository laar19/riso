import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/chat_thread.dart';
import '../../models/chat_message.dart';
import '../../models/email_account.dart';

class DatabaseService {
  static const _threadsBox = 'threads';
  static const _messagesBox = 'messages';
  static const _emailAccountsBox = 'emailAccounts';
  static const _metaBox = 'riso_meta';
  static const _schemaVersion = 1;
  static const _schemaVersionKey = 'schema_version';

  late Box<String> _threadsBox_;
  late Box<String> _messagesBox_;
  late Box<String> _emailAccountsBox_;
  late Box<String> _metaBox_;

  Future<void> init() async {
    _metaBox_ = await Hive.openBox<String>(
      _metaBox,
      encryptionCipher: await _getCipher('hive_meta'),
    );

    await _runMigrations();

    _threadsBox_ = await Hive.openBox<String>(
      _threadsBox,
      encryptionCipher: await _getCipher('hive_threads'),
    );
    _messagesBox_ = await Hive.openBox<String>(
      _messagesBox,
      encryptionCipher: await _getCipher('hive_messages'),
    );
    _emailAccountsBox_ = await Hive.openBox<String>(
      _emailAccountsBox,
      encryptionCipher: await _getCipher('hive_email'),
    );
  }

  Future<AesCipher?> _getCipher(String boxName) async {
    const storage = FlutterSecureStorage();
    final keyStr = await storage.read(key: 'riso_hive_key_$boxName');
    if (keyStr != null) {
      return AesCipher(base64Url.decode(keyStr));
    }
    final key = Hive.generateSecureKey();
    await storage.write(
      key: 'riso_hive_key_$boxName',
      value: base64Url.encode(key),
    );
    return AesCipher(key);
  }

  Future<void> _runMigrations() async {
    final currentVersion = _metaBox_.get(_schemaVersionKey);
    final storedVersion = currentVersion != null ? int.tryParse(currentVersion) ?? 0 : 0;

    if (storedVersion < _schemaVersion) {
      await _migrateV0toV1();
    }

    await _metaBox_.put(_schemaVersionKey, _schemaVersion.toString());
  }

  Future<void> _migrateV0toV1() async {
    // V0 → V1: Los mensajes ahora tienen campo modelUsed opcional.
    // ChatThread ahora tiene messageCount.
    // EmailAccount ahora tiene displayName.
    // No hay cambios rompientes de esquema porque usamos ??
    // Esta migración es un placeholder para futuras migraciones.
  }

  Future<bool> _safeFromJson<T>(
    String json, {
    required T Function(Map<String, dynamic>) fromJson,
    T? defaultValue,
  }) async {
    try {
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) {
        fromJson(parsed);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<ChatThread>> getAllThreads() async {
    final results = <ChatThread>[];
    for (final entry in _threadsBox_.entries) {
      try {
        final thread = ChatThread.fromJson(
          jsonDecode(entry.value) as Map<String, dynamic>,
        );
        results.add(thread);
      } catch (_) {
        // Saltar registros corruptos
      }
    }
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  Future<void> saveThread(ChatThread thread) async {
    await _threadsBox_.put(thread.id, jsonEncode(thread.toJson()));
  }

  Future<void> deleteThread(String id) async {
    await _threadsBox_.delete(id);
    final keys = _messagesBox_.keys.where((k) => k.startsWith('$id:'));
    for (final key in keys) {
      await _messagesBox_.delete(key);
    }
  }

  Future<List<ChatMessage>> getMessages(String threadId) async {
    final results = <ChatMessage>[];
    final keys = _messagesBox_.keys.where((k) => k.startsWith('$threadId:'));
    for (final key in keys) {
      try {
        final value = _messagesBox_.get(key);
        if (value != null) {
          results.add(ChatMessage.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ));
        }
      } catch (_) {
        // Saltar registros corruptos
      }
    }
    results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return results;
  }

  Future<void> saveMessage(ChatMessage message) async {
    await _messagesBox_.put(
      '${message.threadId}:${message.id}',
      jsonEncode(message.toJson()),
    );
  }

  Future<void> deleteMessage(String threadId, String messageId) async {
    await _messagesBox_.delete('$threadId:$messageId');
  }

  Future<List<EmailAccount>> getAllEmailAccounts() async {
    final results = <EmailAccount>[];
    for (final entry in _emailAccountsBox_.entries) {
      try {
        results.add(EmailAccount.fromJson(
          jsonDecode(entry.value) as Map<String, dynamic>,
        ));
      } catch (_) {
        // Saltar registros corruptos
      }
    }
    return results;
  }

  Future<void> saveEmailAccount(EmailAccount account) async {
    await _emailAccountsBox_.put(account.id, jsonEncode(account.toJson()));
  }

  Future<void> deleteEmailAccount(String id) async {
    await _emailAccountsBox_.delete(id);
  }

  Future<void> importThreads(List<ChatThread> threads) async {
    for (final thread in threads) {
      if (!_threadsBox_.containsKey(thread.id)) {
        await saveThread(thread);
      }
    }
  }

  Future<void> importMessages(List<ChatMessage> messages) async {
    for (final message in messages) {
      final key = '${message.threadId}:${message.id}';
      if (!_messagesBox_.containsKey(key)) {
        await saveMessage(message);
      }
    }
  }
}
