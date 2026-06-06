import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/settings_provider.dart';
import '../../../providers/planning_mode_provider.dart';
import '../../../models/llm_provider.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../email/presentation/email_account_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isPlanning = ref.watch(planningModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(theme, 'LLM Provider'),
          Card(
            child: Column(
              children: [
                for (final provider in LLMProvider.values)
                  RadioListTile<LLMProvider>(
                    title: Text(provider.displayName),
                    subtitle: Text(provider.defaultModel),
                    value: provider,
                    groupValue: settings.selectedProvider,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).selectProvider(v);
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Modelo'),
              subtitle: Text(settings.selectedModel),
              trailing: const Icon(Icons.edit),
              onTap: () => _showModelDialog(context, ref, settings),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'API Keys'),
          Card(
            child: Column(
              children: [
                _apiKeyTile(
                  context,
                  ref,
                  'Google Gemini',
                  Icons.auto_awesome,
                  settings.apiKeys['gemini'] ?? '',
                  'gemini',
                  theme,
                ),
                const Divider(height: 1),
                _apiKeyTile(
                  context,
                  ref,
                  'OpenAI',
                  Icons.open_in_new,
                  settings.apiKeys['openai'] ?? '',
                  'openai',
                  theme,
                ),
                const Divider(height: 1),
                _apiKeyTile(
                  context,
                  ref,
                  'Anthropic Claude',
                  Icons.psychology,
                  settings.apiKeys['claude'] ?? '',
                  'claude',
                  theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Seguridad'),
          Card(
            child: SwitchListTile(
              title: const Text('Modo Planificación'),
              subtitle: const Text(
                'Solo lectura: bloquea acciones de escritura de la IA',
              ),
              value: isPlanning,
              onChanged: (v) {
                ref.read(planningModeProvider.notifier).state = v;
              },
              secondary: Icon(
                isPlanning ? Icons.shield : Icons.flash_on,
                color: isPlanning ? Colors.orange : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Correo Electrónico'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail),
              title: const Text('Cuentas de correo'),
              subtitle: const Text('Gestionar cuentas Gmail e IMAP'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EmailAccountScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Datos'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Respaldo y Restauración'),
              subtitle: const Text('Exportar o importar chats'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Seguridad del dispositivo'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Almacenamiento de claves',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Las API keys y tokens se almacenan cifrados usando el '
                          'hardware de seguridad del dispositivo (Keystore). '
                          'En dispositivos sin respaldo hardware, la protección '
                          'es solo por software.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Riso v1.0.0 — 100% local',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _apiKeyTile(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    String currentKey,
    String provider,
    ThemeData theme,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        currentKey.isNotEmpty
            ? '****${currentKey.substring(currentKey.length - 4)}'
            : 'No configurado',
        style: TextStyle(
          color: currentKey.isNotEmpty ? null : theme.colorScheme.error,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          currentKey.isNotEmpty ? Icons.edit : Icons.add,
        ),
        onPressed: () => _showApiKeyDialog(context, ref, label, provider),
      ),
    );
  }

  void _showApiKeyDialog(
    BuildContext context,
    WidgetRef ref,
    String label,
    String provider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('API Key: $label'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'Ingresa tu API key',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).deleteApiKey(provider);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(settingsProvider.notifier)
                    .saveApiKey(provider, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showModelDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final controller = TextEditingController(text: settings.selectedModel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modelo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre del modelo',
                hintText: 'gemini-1.5-flash',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ejemplos:\n'
              'Gemini: gemini-1.5-flash, gemini-1.5-pro\n'
              'OpenAI: gpt-4o-mini, gpt-4o\n'
              'Claude: claude-3-5-sonnet-20241022',
              style: Theme.of(context).textTheme.bodySmall,
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
              ref
                  .read(settingsProvider.notifier)
                  .selectModel(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
