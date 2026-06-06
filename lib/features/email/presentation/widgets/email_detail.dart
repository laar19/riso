import 'package:flutter/material.dart';
import '../../../../models/email_message.dart';

class EmailDetail extends StatelessWidget {
  final EmailMessage email;
  final void Function() onArchive;
  final void Function() onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onForward;

  const EmailDetail({
    super.key,
    required this.email,
    required this.onArchive,
    required this.onDelete,
    this.onReply,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(email.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outline),
            tooltip: 'Archivar',
            onPressed: onArchive,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            email.subject,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _infoRow(theme, 'De:', email.from.name.isNotEmpty
              ? '${email.from.name} <${email.from.address}>'
              : email.from.address),
          _infoRow(theme, 'Para:', email.to.map((p) => p.address).join(', ')),
          if (email.cc.isNotEmpty)
            _infoRow(theme, 'CC:', email.cc.map((p) => p.address).join(', ')),
          _infoRow(theme, 'Fecha:', _formatDateTime(email.receivedAt)),
          if (email.hasAttachments)
            _infoRow(theme, 'Adjuntos:', 'Sí'),
          const Divider(height: 32),
          SelectableText(
            email.bodyPlain,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply),
                  label: const Text('Responder'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onForward,
                  icon: const Icon(Icons.forward),
                  label: const Text('Reenviar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
