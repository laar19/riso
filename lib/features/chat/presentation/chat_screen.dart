import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/chat_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../models/llm_provider.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input.dart';
import 'widgets/thread_list.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _showThreads = false;

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(chatState.currentThread?.title ?? 'Riso Chat'),
        actions: [
          if (chatState.currentThread != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nuevo chat',
              onPressed: _showNewThreadDialog,
            ),
          IconButton(
            icon: Icon(_showThreads ? Icons.close : Icons.history),
            tooltip: 'Historial',
            onPressed: () => setState(() => _showThreads = !_showThreads),
          ),
        ],
      ),
      body: Row(
        children: [
          if (_showThreads)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: _showNewThreadDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo chat'),
                    ),
                  ),
                  Expanded(
                    child: ThreadList(
                      threads: chatState.threads,
                      selected: chatState.currentThread,
                      onSelect: (thread) {
                        ref
                            .read(chatProvider.notifier)
                            .selectThread(thread);
                        setState(() => _showThreads = false);
                      },
                      onDelete: (id) {
                        ref.read(chatProvider.notifier).deleteThread(id);
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                if (chatState.error != null)
                  MaterialBanner(
                    content: Text(chatState.error!),
                    leading: const Icon(Icons.error, color: Colors.red),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            ref.read(chatProvider.notifier).clearError(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                Expanded(
                  child: chatState.currentThread == null
                      ? _emptyState(theme)
                      : chatState.messages.isEmpty &&
                              !chatState.isLoading
                          ? _newChatHint(theme)
                          : _messageList(chatState, theme),
                ),
                if (chatState.currentThread != null)
                  ChatInput(
                    onSend: (text) {
                      ref.read(chatProvider.notifier).sendMessage(text);
                    },
                    enabled: !chatState.isLoading,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Bienvenido a Riso',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona un chat o crea uno nuevo',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showNewThreadDialog,
            icon: const Icon(Icons.add),
            label: const Text('Crear nuevo chat'),
          ),
        ],
      ),
    );
  }

  Widget _newChatHint(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nuevo chat',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe un mensaje para empezar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageList(ChatState chatState, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: chatState.messages.length +
          (chatState.isStreaming || chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < chatState.messages.length) {
          return MessageBubble(message: chatState.messages[index]);
        }

        if (chatState.isStreaming && chatState.streamingContent.isNotEmpty) {
          final streamingMsg = ChatMessage(
            id: 'streaming',
            threadId: chatState.currentThread?.id ?? '',
            role: MessageRole.assistant,
            content: chatState.streamingContent,
            timestamp: DateTime.now(),
            isStreaming: true,
          );
          return MessageBubble(message: streamingMsg);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _showNewThreadDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final provider in LLMProvider.values)
              ListTile(
                title: Text(provider.displayName),
                subtitle: Text(provider.defaultModel),
                leading: const Icon(Icons.smart_toy),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(chatProvider.notifier).createThread(
                        provider: provider,
                        title: 'Chat ${provider.displayName}',
                      );
                },
              ),
          ],
        ),
      ),
    );
  }
}
