import 'package:equatable/equatable.dart';
import 'llm_provider.dart';

class ChatThread extends Equatable {
  final String id;
  final String title;
  final LLMProvider provider;
  final String model;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const ChatThread({
    required this.id,
    required this.title,
    required this.provider,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  ChatThread copyWith({
    String? id,
    String? title,
    LLMProvider? provider,
    String? model,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
  }) {
    return ChatThread(
      id: id ?? this.id,
      title: title ?? this.title,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'provider': provider.name,
        'model': model,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messageCount': messageCount,
      };

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] as String,
        title: json['title'] as String,
        provider: LLMProvider.values.byName(json['provider'] as String),
        model: json['model'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        messageCount: json['messageCount'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        provider,
        model,
        createdAt,
        updatedAt,
        messageCount,
      ];
}
