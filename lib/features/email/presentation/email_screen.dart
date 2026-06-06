import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/email_provider.dart';
import 'widgets/email_list.dart';
import 'widgets/email_detail.dart';
import 'email_account_screen.dart';

class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    final emailState = ref.read(emailProvider);
    if (!emailState.isConnected && emailState.accounts.isNotEmpty) {
      await ref
          .read(emailProvider.notifier)
          .connectAccount(emailState.accounts.first);
    }
    if (emailState.isConnected) {
      await ref.read(emailProvider.notifier).fetchInbox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailState = ref.watch(emailProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          emailState.isConnected
              ? emailState.selectedAccount?.email ?? 'Correo'
              : 'Correo',
        ),
        actions: [
          if (emailState.isConnected) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
              onPressed: () =>
                  ref.read(emailProvider.notifier).fetchInbox(),
            ),
            IconButton(
              icon: const Icon(Icons.link_off),
              tooltip: 'Desconectar',
              onPressed: () =>
                  ref.read(emailProvider.notifier).disconnect(),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar cuentas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmailAccountScreen()),
            ),
          ),
        ],
      ),
      body: emailState.selectedEmail != null
          ? EmailDetail(
              email: emailState.selectedEmail!,
              onArchive: () {
                ref
                    .read(emailProvider.notifier)
                    .archiveEmail(emailState.selectedEmail!.id);
                ref.read(emailProvider.notifier).fetchInbox();
              },
              onDelete: () {
                ref
                    .read(emailProvider.notifier)
                    .deleteEmail(emailState.selectedEmail!.id);
                ref.read(emailProvider.notifier).fetchInbox();
              },
              onReply: () => _showComposeDialog(context, ref, replyTo: emailState.selectedEmail!),
              onForward: () => _showComposeDialog(context, ref, forwardEmail: emailState.selectedEmail!),
            )
          : !emailState.isConnected
              ? _disconnectedState(theme)
              : emailState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : EmailList(
                      emails: emailState.inbox,
                      onSelect: (email) {
                        ref.read(emailProvider.notifier).selectEmail(email.id);
                      },
                    ),
    );
  }

  Widget _disconnectedState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline,
              size: 80, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 24),
          Text(
            'Conecta tu correo',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configura una cuenta para empezar',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmailAccountScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Configurar cuenta'),
          ),
        ],
      ),
    );
  }

  void _showComposeDialog(
      BuildContext context, WidgetRef ref,
      {EmailMessage? replyTo, EmailMessage? forwardEmail}) {
    final toCtrl = TextEditingController(
      text: replyTo != null ? replyTo.from.address : '',
    );
    final subjectCtrl = TextEditingController(
      text: replyTo != null ? 'Re: ${replyTo.subject}' :
            forwardEmail != null ? 'Fw: ${forwardEmail.subject}' : '',
    );
    final bodyCtrl = TextEditingController(
      text: forwardEmail != null
          ? '\n\n--- Mensaje original ---\n${forwardEmail.bodyPlain}'
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(replyTo != null ? 'Responder' :
                    forwardEmail != null ? 'Reenviar' : 'Nuevo correo'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toCtrl,
                decoration: const InputDecoration(labelText: 'Para'),
              ),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Asunto'),
              ),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Mensaje'),
                maxLines: 8,
                minLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(emailProvider.notifier).sendEmail(
                    to: toCtrl.text.trim(),
                    subject: subjectCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
