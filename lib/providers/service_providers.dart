import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage/secure_storage_service.dart';
import '../services/storage/database_service.dart';
import '../services/llm/gemini_service.dart';
import '../services/llm/openai_service.dart';
import '../services/llm/claude_service.dart';
import '../services/llm/llm_resolver.dart';
import '../services/llm/function_calling_handler.dart';
import '../services/email/gmail_api_service.dart';
import '../services/email/imap_smtp_service.dart';
import '../services/email/email_service.dart';
import '../services/backup_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final db = DatabaseService();
  db.init();
  return db;
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final openaiServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});

final claudeServiceProvider = Provider<ClaudeService>((ref) {
  return ClaudeService();
});

final gmailApiServiceProvider = Provider<GmailApiService>((ref) {
  return GmailApiService();
});

final imapSmtpServiceProvider = Provider<ImapSmtpService>((ref) {
  return ImapSmtpService();
});

final emailServiceProvider = Provider<EmailService>((ref) {
  return ref.watch(gmailApiServiceProvider);
});

final functionCallingHandlerProvider = Provider<FunctionCallingHandler>((ref) {
  return FunctionCallingHandler(ref.watch(emailServiceProvider));
});

final llmResolverProvider = Provider<LLMResolver>((ref) {
  return LLMResolver(
    gemini: ref.watch(geminiServiceProvider),
    openai: ref.watch(openaiServiceProvider),
    claude: ref.watch(claudeServiceProvider),
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseServiceProvider));
});
