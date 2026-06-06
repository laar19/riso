import 'package:equatable/equatable.dart';

enum EmailProtocol { gmailApi, imapSmtp }

class EmailAccount extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final EmailProtocol protocol;
  final bool isActive;

  const EmailAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.protocol,
    this.isActive = true,
  });

  EmailAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    EmailProtocol? protocol,
    bool? isActive,
  }) {
    return EmailAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      protocol: protocol ?? this.protocol,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'protocol': protocol.name,
        'isActive': isActive,
      };

  factory EmailAccount.fromJson(Map<String, dynamic> json) => EmailAccount(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String? ?? json['email'] as String,
        protocol: EmailProtocol.values.byName(json['protocol'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, email, displayName, protocol, isActive];
}
