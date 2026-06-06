import 'package:flutter_test/flutter_test.dart';
import 'package:riso/models/email_message.dart';

void main() {
  group('EmailParticipant', () {
    test('fromString parsea formato "Nombre <email>"', () {
      final p = EmailParticipant.fromString('Juan Pérez <juan@example.com>');
      expect(p.name, 'Juan Pérez');
      expect(p.address, 'juan@example.com');
    });

    test('fromString parsea solo email', () {
      final p = EmailParticipant.fromString('juan@example.com');
      expect(p.name, 'juan@example.com');
      expect(p.address, 'juan@example.com');
    });

    test('fromString parsea con comillas', () {
      final p = EmailParticipant.fromString('"Juan" <juan@example.com>');
      expect(p.name, 'Juan');
      expect(p.address, 'juan@example.com');
    });

    test('toJson/fromJson simétrico', () {
      final original = EmailParticipant(name: 'Ana', address: 'ana@test.com');
      final json = original.toJson();
      final restored = EmailParticipant.fromJson(json);
      expect(restored.name, 'Ana');
      expect(restored.address, 'ana@test.com');
    });
  });

  group('EmailMessage', () {
    test('toJson y fromJson preservan campos anidados', () {
      final original = EmailMessage(
        id: 'email-1',
        accountId: 'account-1',
        subject: 'Reunión',
        bodyPlain: 'Hola, confirmo asistencia.',
        from: EmailParticipant(name: 'María', address: 'maria@empresa.com'),
        to: [
          EmailParticipant(name: 'Usuario', address: 'user@riso.app'),
        ],
        cc: [
          EmailParticipant(name: 'Jefe', address: 'jefe@empresa.com'),
        ],
        receivedAt: DateTime(2025, 6, 1, 10, 0),
        isRead: true,
        isStarred: false,
        hasAttachments: true,
        labels: ['INBOX', 'IMPORTANT'],
        attachments: [
          EmailAttachment(
            filename: 'documento.pdf',
            mimeType: 'application/pdf',
            size: 1024,
          ),
        ],
      );

      final json = original.toJson();
      final restored = EmailMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.subject, original.subject);
      expect(restored.from.name, original.from.name);
      expect(restored.to.length, 1);
      expect(restored.cc.length, 1);
      expect(restored.attachments.length, 1);
      expect(restored.attachments.first.filename, 'documento.pdf');
    });

    test('copyWith preserva campos no especificados', () {
      final email = EmailMessage(
        id: '1',
        accountId: 'a1',
        subject: 'test',
        bodyPlain: 'body',
        from: EmailParticipant(name: '', address: 'from@test.com'),
        to: [],
        receivedAt: DateTime(2025, 1, 1),
      );

      final updated = email.copyWith(subject: 'modificado', isRead: true);

      expect(updated.subject, 'modificado');
      expect(updated.isRead, true);
      expect(updated.id, '1');
      expect(updated.bodyPlain, 'body');
    });
  });
}
