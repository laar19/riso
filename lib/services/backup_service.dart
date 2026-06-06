import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../models/backup_data.dart';
import '../models/chat_thread.dart';
import '../models/chat_message.dart';
import '../models/email_account.dart';
import 'storage/database_service.dart';

class BackupService {
  final DatabaseService _db;

  BackupService(this._db);

  Future<File> exportBackup() async {
    final threads = await _db.getAllThreads();
    final messages = <ChatMessage>[];
    for (final thread in threads) {
      messages.addAll(await _db.getMessages(thread.id));
    }
    final emailAccounts = await _db.getAllEmailAccounts();

    final backup = BackupData(
      appVersion: '1.0.0',
      exportedAt: DateTime.now(),
      threads: threads,
      messages: messages,
      emailAccounts: emailAccounts,
    );

    final jsonStr =
        const JsonEncoder.withIndent('  ').convert(backup.toJson());
    final encoder = ZipEncoder();
    final archiveObj = Archive();
    archiveObj.addFile(ArchiveFile(
        'riso_backup.json', jsonStr.length, utf8.encode(jsonStr)));

    final zipBytes = encoder.encode(archiveObj);

    // Usar documents dir en vez de temp (compatible con Android 11+)
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final file = File('${backupDir.path}/riso_backup_'
        '${DateTime.now().millisecondsSinceEpoch}.zip');
    await file.writeAsBytes(zipBytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Respaldo Riso',
      text: 'Respaldo de chats y configuración de Riso',
    );

    return file;
  }

  Future<int> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );

    if (result == null || result.files.isEmpty) return 0;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    String jsonStr;

    if (file.path.endsWith('.zip')) {
      final archiveObj = ZipDecoder().decodeBytes(bytes);
      final archiveFile = archiveObj.files.firstWhere(
        (f) => f.name == 'riso_backup.json',
        orElse: () =>
            throw Exception('No se encontró riso_backup.json en el ZIP'),
      );
      jsonStr = utf8.decode(archiveFile.content as List<int>);
    } else {
      jsonStr = utf8.decode(bytes);
    }

    final backup =
        BackupData.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

    final added = backup.threads.length + backup.messages.length;

    await _db.importThreads(backup.threads);
    await _db.importMessages(backup.messages);

    for (final account in backup.emailAccounts) {
      await _db.saveEmailAccount(account);
    }

    return added;
  }
}
