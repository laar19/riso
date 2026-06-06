import 'package:equatable/equatable.dart';

class EmailParticipant extends Equatable {
  final String name;
  final String address;

  const EmailParticipant({required this.name, required this.address});

  factory EmailParticipant.fromString(String raw) {
    final match = RegExp(r'"?([^"]*)"?\s*<(.+)>').firstMatch(raw);
    if (match != null) {
      return EmailParticipant(
        name: match.group(1)!.trim(),
        address: match.group(2)!.trim(),
      );
    }
    return EmailParticipant(name: raw, address: raw);
  }

  Map<String, dynamic> toJson() => {'name': name, 'address': address};

  factory EmailParticipant.fromJson(Map<String, dynamic> json) =>
      EmailParticipant(
        name: json['name'] as String? ?? '',
        address: json['address'] as String,
      );

  @override
  List<Object?> get props => [name, address];
}

class EmailMessage extends Equatable {
  final String id;
  final String accountId;
  final String? threadId;
  final List<String> labels;
  final EmailParticipant from;
  final List<EmailParticipant> to;
  final List<EmailParticipant> cc;
  final List<EmailParticipant> bcc;
  final String subject;
  final String bodyPlain;
  final String? bodyHtml;
  final DateTime receivedAt;
  final bool isRead;
  final bool isStarred;
  final bool hasAttachments;
  final List<EmailAttachment> attachments;

  const EmailMessage({
    required this.id,
    required this.accountId,
    this.threadId,
    this.labels = const [],
    required this.from,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    required this.subject,
    required this.bodyPlain,
    this.bodyHtml,
    required this.receivedAt,
    this.isRead = false,
    this.isStarred = false,
    this.hasAttachments = false,
    this.attachments = const [],
  });

  EmailMessage copyWith({
    String? id,
    String? accountId,
    String? threadId,
    List<String>? labels,
    EmailParticipant? from,
    List<EmailParticipant>? to,
    List<EmailParticipant>? cc,
    List<EmailParticipant>? bcc,
    String? subject,
    String? bodyPlain,
    String? bodyHtml,
    DateTime? receivedAt,
    bool? isRead,
    bool? isStarred,
    bool? hasAttachments,
    List<EmailAttachment>? attachments,
  }) {
    return EmailMessage(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      threadId: threadId ?? this.threadId,
      labels: labels ?? this.labels,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      bodyPlain: bodyPlain ?? this.bodyPlain,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'threadId': threadId,
        'labels': labels,
        'from': from.toJson(),
        'to': to.map((e) => e.toJson()).toList(),
        'cc': cc.map((e) => e.toJson()).toList(),
        'bcc': bcc.map((e) => e.toJson()).toList(),
        'subject': subject,
        'bodyPlain': bodyPlain,
        'bodyHtml': bodyHtml,
        'receivedAt': receivedAt.toIso8601String(),
        'isRead': isRead,
        'isStarred': isStarred,
        'hasAttachments': hasAttachments,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  factory EmailMessage.fromJson(Map<String, dynamic> json) => EmailMessage(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        threadId: json['threadId'] as String?,
        labels: (json['labels'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        from: EmailParticipant.fromJson(json['from'] as Map<String, dynamic>),
        to: (json['to'] as List<dynamic>?)
                ?.map((e) =>
                    EmailParticipant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        cc: (json['cc'] as List<dynamic>?)
                ?.map((e) =>
                    EmailParticipant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        bcc: (json['bcc'] as List<dynamic>?)
                ?.map((e) =>
                    EmailParticipant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        subject: json['subject'] as String,
        bodyPlain: json['bodyPlain'] as String? ?? '',
        bodyHtml: json['bodyHtml'] as String?,
        receivedAt: DateTime.parse(json['receivedAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
        isStarred: json['isStarred'] as bool? ?? false,
        hasAttachments: json['hasAttachments'] as bool? ?? false,
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((e) =>
                    EmailAttachment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [
        id,
        accountId,
        threadId,
        labels,
        from,
        to,
        cc,
        bcc,
        subject,
        bodyPlain,
        bodyHtml,
        receivedAt,
        isRead,
        isStarred,
        hasAttachments,
        attachments,
      ];
}

class EmailAttachment extends Equatable {
  final String filename;
  final String? mimeType;
  final int size;
  final String? dataBase64;

  const EmailAttachment({
    required this.filename,
    this.mimeType,
    this.size = 0,
    this.dataBase64,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'mimeType': mimeType,
        'size': size,
        'dataBase64': dataBase64,
      };

  factory EmailAttachment.fromJson(Map<String, dynamic> json) =>
      EmailAttachment(
        filename: json['filename'] as String,
        mimeType: json['mimeType'] as String?,
        size: json['size'] as int? ?? 0,
        dataBase64: json['dataBase64'] as String?,
      );

  @override
  List<Object?> get props => [filename, mimeType, size, dataBase64];
}
