import 'package:flutter/material.dart';
import '../../../../models/chat_thread.dart';

class ThreadList extends StatelessWidget {
  final List<ChatThread> threads;
  final ChatThread? selected;
  final void Function(ChatThread) onSelect;
  final void Function(String) onDelete;

  const ThreadList({
    super.key,
    required this.threads,
    this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Sin conversaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un nuevo chat para empezar',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        final isSelected = thread.id == selected?.id;

        return ListTile(
          selected: isSelected,
          selectedTileColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          leading: CircleAvatar(
            child: Text(thread.title.isNotEmpty
                ? thread.title[0].toUpperCase()
                : '?'),
          ),
          title: Text(
            thread.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            thread.provider.displayName,
            style: theme.textTheme.bodySmall,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => onDelete(thread.id),
          ),
          onTap: () => onSelect(thread),
        );
      },
    );
  }
}
