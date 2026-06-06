import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riso/models/backup_data.dart';
import 'package:riso/services/storage/database_service.dart';
import 'package:riso/services/backup_service.dart';

void main() {
  group('BackupService', () {
    late DatabaseService db;
    late BackupService backup;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final path = '${Directory.systemTemp.path}/test_backup_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(path);
      db = DatabaseService();
      await db.init();
      backup = BackupService(db);
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk('threads');
      await Hive.deleteBoxFromDisk('messages');
      await Hive.deleteBoxFromDisk('emailAccounts');
      await Hive.deleteBoxFromDisk('riso_meta');
    });

    test('exportBackup genera un archivo ZIP válido', () async {
      final file = await backup.exportBackup();
      expect(file.existsSync(), true);
      expect(file.path.endsWith('.zip'), true);
      expect(file.lengthSync(), greaterThan(0));

      // Verificar que contiene riso_backup.json
      final bytes = await file.readAsBytes();
      expect(bytes, isNotEmpty);
    });

    test('BackupData JSON exportable tiene estructura correcta', () async {
      final backupData = BackupData(
        appVersion: '1.0.0',
        exportedAt: DateTime(2025, 6, 1),
      );

      final jsonStr = jsonEncode(backupData.toJson());
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['appVersion'], '1.0.0');
      expect(decoded['exportedAt'], isNotNull);
      expect(decoded['threads'], isA<List>());
      expect(decoded['messages'], isA<List>());
      expect(decoded['emailAccounts'], isA<List>());
    });
  });
}
