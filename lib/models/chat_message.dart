import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }

class ChatMessage extends Equatable {
  final String id;
  final String threadId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? toolCalls;
  final Map<String, dynamic>? toolResults;
  final bool isStreaming;
  final String? modelUsed;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.toolCalls,
    this.toolResults,
    this.isStreaming = false,
    this.modelUsed,
  });

  ChatMessage copyWith({
    String? id,
    String? threadId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    Map<String, dynamic>? toolCalls,
    Map<String, dynamic>? toolResults,
    bool? isStreaming,
    String? modelUsed,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      toolCalls: toolCalls ?? this.toolCalls,
      toolResults: toolResults ?? this.toolResults,
      isStreaming: isStreaming ?? this.isStreaming,
      modelUsed: modelUsed ?? this.modelUsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'threadId': threadId,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'toolCalls': toolCalls,
        'toolResults': toolResults,
        'isStreaming': isStreaming,
        'modelUsed': modelUsed,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        threadId: json['threadId'] as String,
        role: MessageRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        toolCalls: json['toolCalls'] as Map<String, dynamic>?,
        toolResults: json['toolResults'] as Map<String, dynamic>?,
        isStreaming: json['isStreaming'] as bool? ?? false,
        modelUsed: json['modelUsed'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        threadId,
        role,
        content,
        timestamp,
        toolCalls,
        toolResults,
        isStreaming,
        modelUsed,
      ];
}
