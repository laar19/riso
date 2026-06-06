import 'package:equatable/equatable.dart';
import 'chat_thread.dart';
import 'chat_message.dart';
import 'email_account.dart';

class BackupData extends Equatable {
  final String appVersion;
  final DateTime exportedAt;
  final List<ChatThread> threads;
  final List<ChatMessage> messages;
  final List<EmailAccount> emailAccounts;

  const BackupData({
    required this.appVersion,
    required this.exportedAt,
    this.threads = const [],
    this.messages = const [],
    this.emailAccounts = const [],
  });

  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'exportedAt': exportedAt.toIso8601String(),
        'threads': threads.map((t) => t.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'emailAccounts': emailAccounts.map((a) => a.toJson()).toList(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
        appVersion: json['appVersion'] as String? ?? 'unknown',
        exportedAt: json['exportedAt'] != null
            ? DateTime.parse(json['exportedAt'] as String)
            : DateTime.now(),
        threads: (json['threads'] as List<dynamic>?)
                ?.map((e) =>
                    ChatThread.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        messages: (json['messages'] as List<dynamic>?)
                ?.map((e) =>
                    ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        emailAccounts: (json['emailAccounts'] as List<dynamic>?)
                ?.map((e) =>
                    EmailAccount.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props =>
      [appVersion, exportedAt, threads, messages, emailAccounts];
}
