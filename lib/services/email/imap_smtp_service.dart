import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../models/email_message.dart';
import '../../models/email_account.dart';
import 'email_service.dart';

class ImapSmtpService implements EmailService {
  bool _connected = false;
  EmailAccount? _account;

  String? _imapHost;
  int _imapPort = 993;
  String? _smtpHost;
  int _smtpPort = 587;
  String? _password;

  SecureSocket? _imapSocket;
  SecureSocket? _smtpSocket;

  static const _lineEnding = '\r\n';

  void configure({
    required String imapHost,
    int imapPort = 993,
    required String smtpHost,
    int smtpPort = 587,
    required String password,
  }) {
    _imapHost = imapHost;
    _imapPort = imapPort;
    _smtpHost = smtpHost;
    _smtpPort = smtpPort;
    _password = password;
  }

  @override
  Future<void> connect(EmailAccount account) async {
    _account = account;
    if (_imapHost == null || _password == null) {
      throw Exception('IMAP no configurado');
    }

    await _connectImap();
    await _connectSmtp();
    _connected = true;
  }

  Future<void> _connectImap() async {
    _imapSocket = await SecureSocket.connect(
      _imapHost!,
      _imapPort,
      timeout: const Duration(seconds: 15),
    );

    await _readUntilTag(_imapSocket!, 'OK');
    await _sendImap('LOGIN ${_account!.email} $_password');
    final loginResponse = await _readUntilTag(_imapSocket!, 'OK');
    if (loginResponse.contains('NO') || loginResponse.contains('BAD')) {
      throw Exception('Error de autenticación IMAP: $loginResponse');
    }
  }

  Future<void> _connectSmtp() async {
    _smtpSocket = await SecureSocket.connect(
      _smtpHost!,
      _smtpPort,
      timeout: const Duration(seconds: 15),
    );

    await _readUntilCode(_smtpSocket!, 220);
    final ehlo = 'EHLO riso${_lineEnding}';
    _smtpSocket!.write(ehlo);
    await _readUntilCode(_smtpSocket!, 250);

    _smtpSocket!.write('AUTH LOGIN${_lineEnding}');
    await _readUntilCode(_smtpSocket!, 334);

    final userB64 = base64.encode(utf8.encode(_account!.email));
    _smtpSocket!.write('$userB64${_lineEnding}');
    await _readUntilCode(_smtpSocket!, 334);

    final passB64 = base64.encode(utf8.encode(_password!));
    _smtpSocket!.write('$passB64${_lineEnding}');
    final authResponse = await _readUntilCode(_smtpSocket!, 235);
    if (authResponse == null) {
      throw Exception('Error de autenticación SMTP');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      if (_imapSocket != null) {
        await _sendImap('LOGOUT');
        await _imapSocket!.close();
      }
    } catch (_) {}
    try {
      if (_smtpSocket != null) {
        _smtpSocket!.write('QUIT$_lineEnding');
        await _smtpSocket!.close();
      }
    } catch (_) {}
    _imapSocket = null;
    _smtpSocket = null;
    _connected = false;
    _account = null;
  }

  @override
  bool get isConnected => _connected;

  int _tagCounter = 0;
  String get _nextTag => "a${_tagCounter++}";

  Future<String> _sendImap(String command) async {
    final tag = _nextTag;
    _imapSocket!.write('$tag $command$_lineEnding');
    await _imapSocket!.flush();
    return _readUntilTag(_imapSocket!, tag);
  }

  Future<String> _readUntilTag(SecureSocket socket, String expected) async {
    final buffer = StringBuffer();
    while (true) {
      final line = await _readLine(socket);
      buffer.writeln(line);
      if (line.startsWith('* $expected') ||
          line.startsWith('$expected') ||
          line.contains('$expected')) {
        break;
      }
    }
    return buffer.toString();
  }

  Future<String?> _readUntilCode(SecureSocket socket, int expectedCode) async {
    final buffer = StringBuffer();
    while (true) {
      final line = await _readLine(socket);
      if (line == null) return null;
      buffer.writeln(line);
      if (line.startsWith('$expectedCode ')) break;
    }
    return buffer.toString();
  }

  Future<String> _readLine(SecureSocket socket) async {
    final bytes = <int>[];
    while (true) {
      final byte = await socket.first;
      bytes.add(byte);
      if (bytes.length >= 2 &&
          bytes[bytes.length - 2] == 13 &&
          bytes[bytes.length - 1] == 10) {
        break;
      }
    }
    return utf8.decode(bytes.sublist(0, bytes.length - 2));
  }

  String? _parseSubject(List<String> headers) {
    for (final h in headers) {
      if (h.startsWith('Subject:')) {
        final raw = h.substring(8).trim();
        if (raw.contains('=?UTF-8?B?')) {
          final match = RegExp(r'=\?UTF-8\?B\?([^?]+)\?=').firstMatch(raw);
          if (match != null) {
            return utf8.decode(base64.decode(match.group(1)!));
          }
        }
        if (raw.contains('=?UTF-8?Q?')) {
          final match = RegExp(r'=\?UTF-8\?Q\?([^?]+)\?=').firstMatch(raw);
          if (match != null) {
            return _decodeQuotedPrintable(match.group(1)!);
          }
        }
        return raw;
      }
    }
    return '(Sin asunto)';
  }

  String _decodeQuotedPrintable(String input) {
    final bytes = <int>[];
    for (int i = 0; i < input.length; i++) {
      if (input[i] == '=' && i + 2 < input.length) {
        bytes.add(int.parse(input.substring(i + 1, i + 3), radix: 16));
        i += 2;
      } else {
        bytes.add(input.codeUnitAt(i));
      }
    }
    return utf8.decode(bytes);
  }

  String? _parseFrom(List<String> headers) {
    for (final h in headers) {
      if (h.startsWith('From:')) {
        return h.substring(5).trim();
      }
    }
    return null;
  }

  String? _parseTo(List<String> headers) {
    for (final h in headers) {
      if (h.startsWith('To:')) {
        return h.substring(3).trim();
      }
    }
    return null;
  }

  @override
  Future<List<EmailMessage>> fetchInbox({int maxResults = 20}) async {
    if (!_connected) throw Exception('IMAP no conectado');
    await _sendImap('SELECT INBOX');

    final searchResp = await _sendImap('SEARCH ALL');
    final ids = RegExp(r'\d+').allMatches(searchResp).map((m) => m.group(0)!).toList();
    final recent = ids.reversed.take(maxResults).toList();

    final results = <EmailMessage>[];
    for (final id in recent) {
      final fetchResp = await _sendImap('FETCH $id (BODY[HEADER.FIELDS (SUBJECT FROM TO DATE)])');
      final responseLines = fetchResp.split('\n');
      final heders = responseLines.where((l) => !l.startsWith('*') && !l.startsWith('a')).toList();

      final fromRaw = _parseFrom(heders);
      final toRaw = _parseTo(heders);
      final subject = _parseSubject(heders) ?? '(Sin asunto)';

      final bodyResp = await _sendImap('FETCH $id (BODY[TEXT])');
      final body = _extractBody(bodyResp);

      results.add(EmailMessage(
        id: id,
        accountId: _account?.id ?? '',
        subject: subject,
        bodyPlain: body,
        from: fromRaw != null ? EmailParticipant.fromString(fromRaw) : EmailParticipant(name: '', address: ''),
        to: toRaw != null ? [EmailParticipant.fromString(toRaw)] : [],
        receivedAt: DateTime.now(),
        isRead: false,
      ));
    }

    return results;
  }

  String _extractBody(String fetchResponse) {
    final match = RegExp(r'BODY\[TEXT\]\s*\{(?:\d+)\}\s*\n(.*?)(?=\na\d+\s|$)',
        dotAll: true).firstMatch(fetchResponse);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    final simpleMatch = RegExp(r'BODY\[TEXT\]\s+"([^"]*)"').firstMatch(fetchResponse);
    return simpleMatch?.group(1) ?? '';
  }

  @override
  Future<List<EmailMessage>> searchEmails(String query) async {
    if (!_connected) throw Exception('IMAP no conectado');
    await _sendImap('SELECT INBOX');
    final searchResp = await _sendImap('SEARCH SUBJECT "$query"');
    final ids = RegExp(r'\d+').allMatches(searchResp).map((m) => m.group(0)!).toList();
    final results = <EmailMessage>[];
    for (final id in ids.take(20)) {
      final fetchResp = await _sendImap('FETCH $id (BODY[HEADER.FIELDS (SUBJECT FROM)])');
      final lines = fetchResp.split('\n');
      final fromRaw = _parseFrom(lines);
      final subject = _parseSubject(lines) ?? '(Sin asunto)';
      results.add(EmailMessage(
        id: id,
        accountId: _account?.id ?? '',
        subject: subject,
        bodyPlain: '',
        from: fromRaw != null ? EmailParticipant.fromString(fromRaw) : EmailParticipant(name: '', address: ''),
        to: [],
        receivedAt: DateTime.now(),
      ));
    }
    return results;
  }

  @override
  Future<EmailMessage> getEmail(String id) async {
    if (!_connected) throw Exception('IMAP no conectado');
    final fetchResp = await _sendImap('FETCH $id (BODY[])');
    final fromRaw = _extractHeader(fetchResp, 'From:');
    final subject = _extractHeader(fetchResp, 'Subject:') ?? '(Sin asunto)';
    final body = _extractBody(fetchResp);
    return EmailMessage(
      id: id,
      accountId: _account?.id ?? '',
      subject: subject,
      bodyPlain: body,
      from: EmailParticipant.fromString(fromRaw ?? ''),
      to: [],
      receivedAt: DateTime.now(),
    );
  }

  String? _extractHeader(String response, String headerName) {
    for (final line in response.split('\n')) {
      if (line.startsWith(headerName)) {
        return line.substring(headerName.length).trim();
      }
    }
    return null;
  }

  @override
  Future<void> markAsRead(String id) async {
    if (!_connected) return;
    await _sendImap('STORE $id +FLAGS (\\Seen)');
  }

  @override
  Future<void> markAsUnread(String id) async {
    if (!_connected) return;
    await _sendImap('STORE $id -FLAGS (\\Seen)');
  }

  @override
  Future<void> archive(String id) async {
    if (!_connected) return;
    await _sendImap('COPY $id "[Gmail]/All Mail"');
    await _sendImap('STORE $id +FLAGS (\\Deleted)');
    await _sendImap('EXPUNGE');
  }

  @override
  Future<void> trash(String id) async {
    if (!_connected) return;
    await _sendImap('STORE $id +FLAGS (\\Deleted)');
    await _sendImap('EXPUNGE');
  }

  @override
  Future<void> moveToFolder(String id, String folder) async {
    if (!_connected) return;
    await _sendImap('COPY $id "$folder"');
    await _sendImap('STORE $id +FLAGS (\\Deleted)');
    await _sendImap('EXPUNGE');
  }

  @override
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    List<String>? attachmentPaths,
  }) async {
    if (!_connected || _smtpSocket == null) {
      throw Exception('SMTP no conectado');
    }

    _smtpSocket!.write('MAIL FROM:<${_account!.email}>$_lineEnding');
    await _readUntilCode(_smtpSocket!, 250);

    _smtpSocket!.write('RCPT TO:<$to>$_lineEnding');
    await _readUntilCode(_smtpSocket!, 250);

    _smtpSocket!.write('DATA$_lineEnding');
    await _readUntilCode(_smtpSocket!, 354);

    final message = StringBuffer()
      ..writeln('From: ${_account!.email}')
      ..writeln('To: $to')
      ..writeln('Subject: $subject')
      ..writeln('MIME-Version: 1.0')
      ..writeln('Content-Type: text/plain; charset=UTF-8')
      ..writeln('Content-Transfer-Encoding: 8bit');
    if (cc != null && cc.isNotEmpty) {
      _smtpSocket!.write('RCPT TO:<$cc>$_lineEnding');
      await _readUntilCode(_smtpSocket!, 250);
      message.writeln('Cc: $cc');
    }
    message.writeln();
    message.write(body);
    message.writeln();
    message.write('.$_lineEnding');

    _smtpSocket!.write(message.toString());
    await _smtpSocket!.flush();

    final response = await _readUntilCode(_smtpSocket!, 250);
    if (response == null) {
      throw Exception('Error SMTP al enviar');
    }
  }

  @override
  Future<void> replyTo(String emailId, String body) async {
    final original = await getEmail(emailId);
    await sendEmail(
      to: original.from.address,
      subject: 'Re: ${original.subject}',
      body: body,
    );
  }

  @override
  Future<void> forward(String emailId, String to, String body) async {
    final original = await getEmail(emailId);
    await sendEmail(
      to: to,
      subject: 'Fw: ${original.subject}',
      body: '$body\n\n--- Mensaje original ---\n${original.bodyPlain}',
    );
  }
}
