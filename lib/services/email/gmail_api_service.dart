import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../models/email_message.dart';
import '../../models/email_account.dart';
import 'email_service.dart';

class GmailApiService implements EmailService {
  String? _accessToken;
  bool _connected = false;
  EmailAccount? _account;
  bool _isInitialized = false;

  static const _gmailBase = 'https://gmail.googleapis.com/gmail/v1/users/me';
  static const _scopes = ['https://mail.google.com/'];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  String? getCurrentEmail() {
    return _googleSignIn.currentUser?.email;
  }

  Future<void> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Inicio de sesión cancelado');

    final auth = await account.authentication;
    _accessToken = auth.accessToken;
    _isInitialized = true;
  }

  Future<void> refreshTokenIfNeeded() async {
    if (_googleSignIn.currentUser == null) return;
    final auth = await _googleSignIn.currentUser!.authentication;
    _accessToken = auth.accessToken;
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _googleSignIn.signOut();
    _accessToken = null;
    _isInitialized = false;
  }

  Future<void> revokeAccess() async {
    if (_accessToken != null) {
      try {
        await http.post(
          Uri.parse('https://accounts.google.com/o/oauth2/revoke?token=$_accessToken'),
        );
      } catch (_) {}
    }
    await signOut();
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  Future<http.Response> _authenticatedGet(Uri uri) async {
    var response = await http.get(uri, headers: _headers);
    if (response.statusCode == 401) {
      await refreshTokenIfNeeded();
      response = await http.get(uri, headers: _headers);
    }
    return response;
  }

  Future<http.Response> _authenticatedPost(Uri uri,
      {Map<String, dynamic>? body}) async {
    var response = await http.post(uri,
        headers: _headers, body: body != null ? jsonEncode(body) : null);
    if (response.statusCode == 401) {
      await refreshTokenIfNeeded();
      response = await http.post(uri,
          headers: _headers, body: body != null ? jsonEncode(body) : null);
    }
    return response;
  }

  @override
  Future<void> connect(EmailAccount account) async {
    _account = account;
    if (_accessToken == null) {
      await signIn();
    }
    _connected = _accessToken != null;
  }

  @override
  Future<void> disconnect() async {
    await signOut();
    _connected = false;
    _account = null;
  }

  @override
  bool get isConnected => _connected;

  @override
  Future<List<EmailMessage>> fetchInbox({int maxResults = 20}) async {
    final response = await _authenticatedGet(
      Uri.parse('$_gmailBase/messages?q=in:inbox&maxResults=$maxResults'),
    );
    if (response.statusCode != 200) {
      throw Exception('Gmail API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = data['messages'] as List<dynamic>? ?? [];

    final results = <EmailMessage>[];
    for (final msg in messages.take(maxResults)) {
      final email = await getEmail(msg['id'] as String);
      results.add(email);
    }
    return results;
  }

  @override
  Future<List<EmailMessage>> searchEmails(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final response = await _authenticatedGet(
      Uri.parse('$_gmailBase/messages?q=$encoded'),
    );
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = data['messages'] as List<dynamic>? ?? [];

    final results = <EmailMessage>[];
    for (final msg in messages.take(20)) {
      results.add(await getEmail(msg['id'] as String));
    }
    return results;
  }

  @override
  Future<EmailMessage> getEmail(String id) async {
    final response = await _authenticatedGet(
      Uri.parse('$_gmailBase/messages/$id?format=full'),
    );
    if (response.statusCode != 200) {
      throw Exception('Gmail API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseGmailMessage(data);
  }

  EmailMessage _parseGmailMessage(Map<String, dynamic> data) {
    final payload = data['payload'] as Map<String, dynamic>? ?? {};
    final headers = payload['headers'] as List<dynamic>? ?? [];

    String header(String name) {
      final h = headers.cast<Map<String, dynamic>>().firstWhere(
            (h) => h['name'] == name,
            orElse: () => {'value': ''},
          );
      return h['value'] as String? ?? '';
    }

    String decodeBody(Map<String, dynamic> part) {
      if (part['body']?['data'] != null) {
        final b64 = part['body']['data'] as String;
        return utf8.decode(base64Url.decode(b64));
      }
      if (part['parts'] != null) {
        for (final p in part['parts'] as List) {
          final text = decodeBody(p as Map<String, dynamic>);
          if (text.isNotEmpty) return text;
        }
      }
      return '';
    }

    final body = decodeBody(payload);
    final toRaw = header('To');
    final ccRaw = header('Cc');

    DateTime parseDate(String raw) {
      try {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) return DateTime.now();
        if (trimmed.contains(',')) {
          final parts = trimmed.split(', ');
          if (parts.length > 1) {
            return DateTime.parse(parts.sublist(1).join(' '));
          }
        }
        return DateTime.parse(trimmed);
      } catch (_) {
        return DateTime.now();
      }
    }

    final dateStr = header('Date');

    return EmailMessage(
      id: data['id'] as String,
      accountId: _account?.id ?? '',
      threadId: data['threadId'] as String?,
      subject: header('Subject'),
      bodyPlain: body,
      from: EmailParticipant.fromString(header('From')),
      to: toRaw.isNotEmpty
          ? toRaw
              .split(',')
              .map((s) => EmailParticipant.fromString(s.trim()))
              .toList()
          : [],
      cc: ccRaw.isNotEmpty
          ? ccRaw
              .split(',')
              .map((s) => EmailParticipant.fromString(s.trim()))
              .toList()
          : [],
      receivedAt: parseDate(dateStr),
      isRead:
          !((data['labelIds'] as List<dynamic>?)?.contains('UNREAD') ?? false),
      labels: (data['labelIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hasAttachments: payload['parts'] != null &&
          (payload['parts'] as List).any(
            (p) =>
                p['filename'] != null && (p['filename'] as String).isNotEmpty,
          ),
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    await _authenticatedPost(
      Uri.parse('$_gmailBase/messages/$id/modify'),
      body: {'removeLabelIds': ['UNREAD']},
    );
  }

  @override
  Future<void> markAsUnread(String id) async {
    await _authenticatedPost(
      Uri.parse('$_gmailBase/messages/$id/modify'),
      body: {'addLabelIds': ['UNREAD']},
    );
  }

  @override
  Future<void> archive(String id) async {
    await _authenticatedPost(
      Uri.parse('$_gmailBase/messages/$id/modify'),
      body: {'removeLabelIds': ['INBOX']},
    );
  }

  @override
  Future<void> trash(String id) async {
    await _authenticatedPost(Uri.parse('$_gmailBase/messages/$id/trash'));
  }

  @override
  Future<void> moveToFolder(String id, String folder) async {
    await _authenticatedPost(
      Uri.parse('$_gmailBase/messages/$id/modify'),
      body: {'addLabelIds': [folder]},
    );
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
    final mime = _buildMimeMessage(to, subject, body, cc: cc, bcc: bcc);
    final encoded = base64Url.encode(utf8.encode(mime));

    final response = await _authenticatedPost(
      Uri.parse('$_gmailBase/messages/send'),
      body: {'raw': encoded},
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar correo: ${response.statusCode}');
    }
  }

  String _buildMimeMessage(
    String to,
    String subject,
    String body, {
    String? cc,
    String? bcc,
  }) {
    final buf = StringBuffer()
      ..writeln('From: ${_account?.email ?? ""}')
      ..writeln('To: $to')
      ..writeln('Subject: $subject')
      ..writeln('MIME-Version: 1.0')
      ..writeln('Content-Type: text/plain; charset=UTF-8');
    if (cc != null && cc.isNotEmpty) buf.writeln('Cc: $cc');
    if (bcc != null && bcc.isNotEmpty) buf.writeln('Bcc: $bcc');
    buf.writeln();
    buf.writeln(body);
    return buf.toString();
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
      body:
          '$body\n\n---------- Mensaje original ----------\n${original.bodyPlain}',
    );
  }
}
