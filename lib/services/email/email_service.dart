import '../../models/email_message.dart';
import '../../models/email_account.dart';

abstract class EmailService {
  Future<void> connect(EmailAccount account);
  Future<void> disconnect();
  Future<List<EmailMessage>> fetchInbox({int maxResults = 20});
  Future<List<EmailMessage>> searchEmails(String query);
  Future<EmailMessage> getEmail(String id);
  Future<void> markAsRead(String id);
  Future<void> markAsUnread(String id);
  Future<void> archive(String id);
  Future<void> trash(String id);
  Future<void> moveToFolder(String id, String folder);
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    List<String>? attachmentPaths,
  });
  Future<void> replyTo(String emailId, String body);
  Future<void> forward(String emailId, String to, String body);
  bool get isConnected;
}
