import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/email_account.dart';
import '../models/email_message.dart';
import '../services/email/email_service.dart';
import '../services/email/gmail_api_service.dart';
import '../services/email/imap_smtp_service.dart';
import '../services/storage/database_service.dart';
import '../services/storage/secure_storage_service.dart';
import 'service_providers.dart';

class EmailState {
  final List<EmailAccount> accounts;
  final EmailAccount? selectedAccount;
  final List<EmailMessage> inbox;
  final EmailMessage? selectedEmail;
  final bool isLoading;
  final String? error;
  final bool isConnected;

  const EmailState({
    this.accounts = const [],
    this.selectedAccount,
    this.inbox = const [],
    this.selectedEmail,
    this.isLoading = false,
    this.error,
    this.isConnected = false,
  });

  EmailState copyWith({
    List<EmailAccount>? accounts,
    EmailAccount? selectedAccount,
    List<EmailMessage>? inbox,
    EmailMessage? selectedEmail,
    bool? isLoading,
    String? error,
    bool? isConnected,
  }) {
    return EmailState(
      accounts: accounts ?? this.accounts,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      inbox: inbox ?? this.inbox,
      selectedEmail: selectedEmail ?? this.selectedEmail,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class EmailNotifier extends StateNotifier<EmailState> {
  final DatabaseService _db;
  final SecureStorageService _storage;
  final GmailApiService _gmail;
  final ImapSmtpService _imap;

  EmailNotifier(this._db, this._storage, this._gmail, this._imap)
      : super(const EmailState()) {
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _db.getAllEmailAccounts();
    state = state.copyWith(accounts: accounts);
  }

  Future<void> addGmailAccount({
    required String email,
    required String displayName,
    required String accessToken,
  }) async {
    final id = const Uuid().v4();
    final account = EmailAccount(
      id: id,
      email: email,
      displayName: displayName,
      protocol: EmailProtocol.gmailApi,
    );

    await _storage.saveOAuthToken(email, accessToken);
    await _db.saveEmailAccount(account);
    state = state.copyWith(accounts: [...state.accounts, account]);
  }

  Future<void> addImapAccount({
    required String email,
    required String password,
    required String imapHost,
    required String smtpHost,
    String? displayName,
  }) async {
    final id = const Uuid().v4();
    final account = EmailAccount(
      id: id,
      email: email,
      displayName: displayName ?? email,
      protocol: EmailProtocol.imapSmtp,
    );

    await _storage.saveImapPassword(email, password);
    await _db.saveEmailAccount(account);
    state = state.copyWith(accounts: [...state.accounts, account]);
  }

  Future<void> connectAccount(EmailAccount account) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (account.protocol == EmailProtocol.gmailApi) {
        await _gmail.connect(account);
        final currentUser = await _getCurrentGmailEmail();
        if (currentUser != null && currentUser != account.email) {
          await _gmail.disconnect();
          throw Exception('La cuenta de Google no coincide con $account.email');
        }
        state = state.copyWith(
          selectedAccount: account,
          isConnected: true,
          isLoading: false,
        );
      } else {
        final password = await _storage.readImapPassword(account.email);
        if (password == null) {
          throw Exception('Contraseña IMAP no encontrada');
        }
        final domain = account.email.split('@').last;
        _imap.configure(
          imapHost: 'imap.$domain',
          smtpHost: 'smtp.$domain',
          password: password,
        );
        await _imap.connect(account);
        state = state.copyWith(
          selectedAccount: account,
          isConnected: true,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<String?> _getCurrentGmailEmail() async {
    try {
      return _gmail.getCurrentEmail();
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchInbox() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _getActiveService();
      final emails = await service.fetchInbox();
      state = state.copyWith(inbox: emails, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectEmail(String id) async {
    try {
      final service = _getActiveService();
      final email = await service.getEmail(id);
      state = state.copyWith(selectedEmail: email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    await _getActiveService().markAsRead(id);
  }

  Future<void> markAsUnread(String id) async {
    await _getActiveService().markAsUnread(id);
  }

  Future<void> archiveEmail(String id) async {
    await _getActiveService().archive(id);
    state = state.copyWith(
      inbox: state.inbox.where((e) => e.id != id).toList(),
    );
  }

  Future<void> deleteEmail(String id) async {
    await _getActiveService().trash(id);
    state = state.copyWith(
      inbox: state.inbox.where((e) => e.id != id).toList(),
    );
  }

  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _getActiveService().sendEmail(
        to: to,
        subject: subject,
        body: body,
        cc: cc,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> disconnect() async {
    await _gmail.disconnect();
    await _imap.disconnect();
    state = state.copyWith(
      selectedAccount: null,
      isConnected: false,
      inbox: [],
      selectedEmail: null,
    );
  }

  Future<void> removeAccount(EmailAccount account) async {
    if (account.protocol == EmailProtocol.gmailApi) {
      await _gmail.disconnect();
      await _storage.deleteOAuthToken(account.email);
    } else {
      await _imap.disconnect();
      await _storage.deleteOAuthToken(account.email);
    }
    await _db.deleteEmailAccount(account.id);
    if (state.selectedAccount?.id == account.id) {
      state = state.copyWith(
        selectedAccount: null,
        isConnected: false,
        inbox: [],
      );
    }
    await _loadAccounts();
  }

  EmailService _getActiveService() {
    if (state.selectedAccount?.protocol == EmailProtocol.gmailApi) {
      return _gmail;
    }
    return _imap;
  }
}

final emailProvider =
    StateNotifierProvider<EmailNotifier, EmailState>((ref) {
  return EmailNotifier(
    ref.watch(databaseServiceProvider),
    ref.watch(secureStorageProvider),
    ref.watch(gmailApiServiceProvider),
    ref.watch(imapSmtpServiceProvider),
  );
});
