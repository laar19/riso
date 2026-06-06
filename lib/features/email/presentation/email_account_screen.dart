import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/email_provider.dart';
import '../../../models/email_account.dart';
import '../../../services/email/gmail_api_service.dart';
import '../../../providers/service_providers.dart';

class EmailAccountScreen extends ConsumerWidget {
  const EmailAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailState = ref.watch(emailProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas de Correo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tus cuentas',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (emailState.accounts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.mail_outline,
                        size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No hay cuentas configuradas',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Añade una cuenta de Gmail o IMAP para empezar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...emailState.accounts.map((account) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        account.email[0].toUpperCase(),
                      ),
                    ),
                    title: Text(account.displayName),
                    subtitle: Text(account.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (account.isActive)
                          Icon(Icons.check_circle,
                              color: theme.colorScheme.primary),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => _confirmRemove(context, ref, account),
                        ),
                      ],
                    ),
                    onTap: () async {
                      try {
                        await ref
                            .read(emailProvider.notifier)
                            .connectAccount(account);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                  ),
                )),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showAddAccountDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Añadir cuenta'),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, WidgetRef ref, EmailAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
            '¿Eliminar la cuenta ${account.email}? También se revocará el acceso de Gmail.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(emailProvider.notifier).removeAccount(account);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Añadir cuenta'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _connectGmail(context, ref);
            },
            child: const ListTile(
              leading: Icon(Icons.mail),
              title: Text('Gmail'),
              subtitle: Text('Iniciar sesión con Google (OAuth2)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showImapSetup(context, ref);
            },
            child: const ListTile(
              leading: Icon(Icons.alternate_email),
              title: Text('IMAP/SMTP'),
              subtitle: Text('Outlook, Yahoo, corporativo'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectGmail(BuildContext context, WidgetRef ref) async {
    final gmail = ref.read(gmailApiServiceProvider);
    try {
      await gmail.signIn();
      final email = gmail.getCurrentEmail();
      if (email == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo obtener el correo')),
          );
        }
        return;
      }

      await ref.read(emailProvider.notifier).addGmailAccount(
            email: email,
            displayName: email.split('@').first,
            accessToken: '',
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cuenta $email agregada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showImapSetup(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final imapCtrl = TextEditingController();
    final smtpCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar IMAP/SMTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            TextField(
              controller: imapCtrl,
              decoration: const InputDecoration(
                labelText: 'Servidor IMAP',
                hintText: 'imap.outlook.com',
              ),
            ),
            TextField(
              controller: smtpCtrl,
              decoration: const InputDecoration(
                labelText: 'Servidor SMTP',
                hintText: 'smtp.outlook.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(emailProvider.notifier).addImapAccount(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text,
                    imapHost: imapCtrl.text.trim(),
                    smtpHost: smtpCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
