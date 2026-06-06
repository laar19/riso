import 'package:flutter/material.dart';
import '../../../../models/email_message.dart';

class EmailList extends StatelessWidget {
  final List<EmailMessage> emails;
  final void Function(EmailMessage) onSelect;

  const EmailList({super.key, required this.emails, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (emails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Bandeja de entrada vacía',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        itemCount: emails.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final email = emails[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                email.from.name.isNotEmpty
                    ? email.from.name[0].toUpperCase()
                    : '?',
              ),
            ),
            title: Text(
              email.from.name.isNotEmpty ? email.from.name : email.from.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: email.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight:
                        email.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                Text(
                  email.bodyPlain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDate(email.receivedAt),
                  style: theme.textTheme.labelSmall,
                ),
                if (email.hasAttachments)
                  const Icon(Icons.attachment, size: 16),
              ],
            ),
            onTap: () => onSelect(email),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}
