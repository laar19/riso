import '../../models/email_account.dart';
import '../email/email_service.dart';
import 'function_calling_tools.dart';

class FunctionCallResult {
  final bool isWriteOperation;
  final String description;
  final Map<String, dynamic> result;

  const FunctionCallResult({
    required this.isWriteOperation,
    required this.description,
    required this.result,
  });
}

class FunctionCallingHandler {
  final EmailService _emailService;

  FunctionCallingHandler(this._emailService);

  Future<FunctionCallResult> handleToolCall(
    String name,
    Map<String, dynamic> args,
  ) async {
    final isWrite = writeFunctions.contains(name);

    switch (name) {
      case 'list_inbox':
        final emails = await _emailService.fetchInbox(
          maxResults: (args['maxResults'] as int? ?? 20).clamp(1, 50),
        );
        return FunctionCallResult(
          isWriteOperation: false,
          description: 'Listar bandeja de entrada (${emails.length} correos)',
          result: {
            'emails': emails
                .map((e) => {
                      'id': e.id,
                      'from': e.from.address,
                      'subject': e.subject,
                      'date': e.receivedAt.toIso8601String(),
                      'isRead': e.isRead,
                    })
                .toList(),
          },
        );

      case 'search_emails':
        final emails = await _emailService.searchEmails(
          args['query'] as String? ?? '',
        );
        return FunctionCallResult(
          isWriteOperation: false,
          description: 'Buscar correos: "${args['query']}"',
          result: {
            'emails': emails
                .map((e) => ({
                      'id': e.id,
                      'from': e.from.address,
                      'subject': e.subject,
                      'date': e.receivedAt.toIso8601String(),
                    }))
                .toList(),
          },
        );

      case 'read_email':
        final email = await _emailService.getEmail(args['emailId'] as String);
        return FunctionCallResult(
          isWriteOperation: false,
          description: 'Leer correo: "${email.subject}"',
          result: {
            'id': email.id,
            'from': email.from.address,
            'to': email.to.map((e) => e.address).join(', '),
            'cc': email.cc.map((e) => e.address).join(', '),
            'subject': email.subject,
            'body': email.bodyPlain,
            'date': email.receivedAt.toIso8601String(),
            'isRead': email.isRead,
            'hasAttachments': email.hasAttachments,
          },
        );

      case 'send_email':
        await _emailService.sendEmail(
          to: args['to'] as String,
          subject: args['subject'] as String,
          body: args['body'] as String,
          cc: args['cc'] as String?,
        );
        return FunctionCallResult(
          isWriteOperation: true,
          description:
              'Enviar correo a "${args['to']}" con asunto "${args['subject']}"',
          result: {'status': 'sent', 'to': args['to']},
        );

      case 'reply_to_email':
        await _emailService.replyTo(
          args['emailId'] as String,
          args['body'] as String,
        );
        return FunctionCallResult(
          isWriteOperation: true,
          description: 'Responder al correo ${args['emailId']}',
          result: {'status': 'replied'},
        );

      case 'forward_email':
        await _emailService.forward(
          args['emailId'] as String,
          args['to'] as String,
          args['body'] as String? ?? '',
        );
        return FunctionCallResult(
          isWriteOperation: true,
          description:
              'Reenviar correo ${args['emailId']} a ${args['to']}',
          result: {'status': 'forwarded'},
        );

      case 'mark_as_read':
        await _emailService.markAsRead(args['emailId'] as String);
        return FunctionCallResult(
          isWriteOperation: true,
          description: 'Marcar correo ${args['emailId']} como leído',
          result: {'status': 'marked_as_read'},
        );

      case 'mark_as_unread':
        await _emailService.markAsUnread(args['emailId'] as String);
        return FunctionCallResult(
          isWriteOperation: true,
          description: 'Marcar correo ${args['emailId']} como no leído',
          result: {'status': 'marked_as_unread'},
        );

      case 'archive_email':
        await _emailService.archive(args['emailId'] as String);
        return FunctionCallResult(
          isWriteOperation: true,
          description: 'Archivar correo ${args['emailId']}',
          result: {'status': 'archived'},
        );

      case 'delete_email':
        await _emailService.trash(args['emailId'] as String);
        return FunctionCallResult(
          isWriteOperation: true,
          description: 'Eliminar correo ${args['emailId']}',
          result: {'status': 'trashed'},
        );

      default:
        throw Exception('Función desconocida: $name');
    }
  }
}
