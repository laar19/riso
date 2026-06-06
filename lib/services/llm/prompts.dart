import '../../providers/email_provider.dart';
import '../../providers/settings_provider.dart';

String systemPromptTemplate({
  required bool isPlanningMode,
  EmailState? emailState,
  SettingsState? settingsState,
}) {
  final emailContext = _buildEmailContext(emailState);
  final apiContext = _buildApiContext(settingsState);

  if (isPlanningMode) {
    return _basePrompt([
      'MODO PLANIFICACIÓN (SOLO LECTURA) ACTIVO.',
      '',
      'PUEDES ejecutar funciones de SOLO LECTURA:',
      '- search_emails, read_email, list_inbox',
      '',
      'NO PUEDES ejecutar funciones de escritura:',
      '- send_email, reply_to_email, forward_email',
      '- archive_email, delete_email, mark_as_read, mark_as_unread',
      '',
      'Si el usuario te pide una acción de escritura, EXPLICA qué harías '
          'y di que necesitas que desactiven el Modo Planificación.',
      'NO ejecutes la acción.',
      emailContext,
    ]);
  }

  return _basePrompt([
    'MODO EJECUCIÓN (ACCESO TOTAL) ACTIVO.',
    '',
    'Tienes acceso COMPLETO a todas las herramientas de correo:',
    '- Lectura: search_emails, read_email, list_inbox',
    '- Escritura: send_email, reply_to_email, forward_email,',
    '  archive_email, delete_email, mark_as_read, mark_as_unread',
    '',
    'Puedes ejecutar cualquier acción que el usuario solicite.',
    'Siempre confirma al usuario lo que hiciste después de ejecutar.',
    'Usa las herramientas de forma autónoma cuando sea apropiado.',
    emailContext,
  ]);
}

String _buildEmailContext(EmailState? emailState) {
  if (emailState == null) return '';

  final parts = <String>[];

  final account = emailState.selectedAccount;
  if (account != null) {
    parts.add('Usuario de correo: ${account.email} (${account.protocol.name})');
  }

  if (emailState.isConnected) {
    parts.add(
        'Estado: Conectado. ${emailState.inbox.length} correos en bandeja de entrada.');
    final unread = emailState.inbox.where((e) => !e.isRead).length;
    if (unread > 0) {
      parts.add('$unread correos no leídos.');
    }
  } else {
    parts.add('Estado: Sin conexión de correo activa.');
  }

  if (parts.isEmpty) return '';
  return '\nCONTEXTO DE CORREO:\n${parts.join('\n')}';
}

String _buildApiContext(SettingsState? settings) {
  if (settings == null) return '';

  final parts = <String>[];
  parts.add('Proveedor LLM activo: ${settings.selectedProvider.displayName}');
  parts.add('Modelo: ${settings.selectedModel}');

  final configured = settings.apiKeys.entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => e.key)
      .toList();
  if (configured.isNotEmpty) {
    parts.add('APIs configuradas: ${configured.join(', ')}');
  } else {
    parts.add('ADVERTENCIA: No hay API keys configuradas.');
  }

  return '\nCONTEXTO DE IA:\n${parts.join('\n')}';
}

String _basePrompt(List<String> sections) {
  final allParts = [
    'Eres Riso, un asistente de IA local especializado en gestión de correo electrónico.',
    '',
    ...sections,
    '',
    'CAPACIDADES:',
    '- Gestionar correos electrónicos (leer, buscar, enviar, archivar, eliminar)',
    '- Responder preguntas sobre el contenido de los correos',
    '- Ayudar a redactar y organizar mensajes',
    '',
    'REGLAS:',
    '1. Siempre pregunta antes de enviar un correo (confirma destinatario y contenido)',
    '2. Muestra los resultados de búsqueda de forma clara y organizada',
    '3. Usa Markdown para formatear respuestas cuando sea apropiado',
    '4. Para bloques de código, usa ```lenguaje ``` con el lenguaje apropiado',
    '5. Sé conciso pero informativo en tus respuestas',
    '6. Si algo falla, explica el error al usuario de forma clara',
    '',
    'HERRAMIENTAS DISPONIBLES:',
    'Las herramientas de correo están definidas como funciones que puedes invocar.',
    'Usa la herramienta apropiada según lo que el usuario necesite.',
    '',
    'FORMATO DE RESPUESTA:',
    '- Usa Markdown para formatear',
    '- Para listas de correos, usa tabla o viñetas',
    '- Fechas en formato legible (ej: "15 de enero de 2025")',
    '',
  ];

  return allParts.join('\n');
}
