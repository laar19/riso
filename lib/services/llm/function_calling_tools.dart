Map<String, dynamic> emailToolsDefinition = {
  'search_emails': {
    'name': 'search_emails',
    'description':
        'Buscar correos electrónicos en la bandeja de entrada usando una consulta',
    'parameters': {
      'query': {
        'type': 'string',
        'description': 'Términos de búsqueda (remitente, asunto, palabras clave)',
      },
      'maxResults': {
        'type': 'integer',
        'description': 'Número máximo de resultados (máximo 50)',
      },
    },
  },
  'read_email': {
    'name': 'read_email',
    'description': 'Leer el contenido de un correo electrónico específico',
    'parameters': {
      'emailId': {
        'type': 'string',
        'description': 'ID del correo electrónico',
        'required': true,
      },
    },
  },
  'send_email': {
    'name': 'send_email',
    'description': 'Enviar un nuevo correo electrónico',
    'parameters': {
      'to': {
        'type': 'string',
        'description': 'Dirección de correo del destinatario',
        'required': true,
      },
      'subject': {
        'type': 'string',
        'description': 'Asunto del correo',
        'required': true,
      },
      'body': {
        'type': 'string',
        'description': 'Contenido del mensaje',
        'required': true,
      },
      'cc': {
        'type': 'string',
        'description': 'Dirección de CC (opcional)',
      },
    },
  },
  'reply_to_email': {
    'name': 'reply_to_email',
    'description': 'Responder a un correo electrónico existente',
    'parameters': {
      'emailId': {
        'type': 'string',
        'description': 'ID del correo al que responder',
        'required': true,
      },
      'body': {
        'type': 'string',
        'description': 'Contenido de la respuesta',
        'required': true,
      },
    },
  },
  'forward_email': {
    'name': 'forward_email',
    'description': 'Reenviar un correo electrónico a otra dirección',
    'parameters': {
      'emailId': {
        'type': 'string',
        'description': 'ID del correo a reenviar',
        'required': true,
      },
      'to': {
        'type': 'string',
        'description': 'Dirección de correo del destinatario',
        'required': true,
      },
      'body': {
        'type': 'string',
        'description': 'Mensaje adicional para el reenvío',
      },
    },
  },
  'mark_as_read': {
    'name': 'mark_as_read',
    'description': 'Marcar un correo como leído',
    'parameters': {
      'emailId': {
        'type': 'string',
        'description': 'ID del correo',
        'required': true,
      },
    },
  },
  'mark_as_unread': {
    'name': 'mark_as_unread',
    'description': 'Marcar un correo como no leído',
    'parameters': {
      'emailId': {
        'type': 'string',
        'description': 'ID del correo',
        'required': true,
      },
    },
  },
  'archive_email': {
    'name': 'archive_email',
    'description': 'Archivar un correo electrónico',
    'parameters': {
      'emailId': {
        'type': 'string',
        'description': 'ID del correo a archivar',
        'required': true,
      },
    },
  },
  'delete_email': {
    'name': 'delete_email',
    'description': 'Mover un correo a la papelera',
    'parameters': {
      'emailId': {
        'type': 'string',
        'description': 'ID del correo a eliminar',
        'required': true,
      },
    },
  },
  'list_inbox': {
    'name': 'list_inbox',
    'description': 'Listar los correos más recientes de la bandeja de entrada',
    'parameters': {
      'maxResults': {
        'type': 'integer',
        'description': 'Número de correos a listar (máximo 20)',
      },
    },
  },
};

final List<Map<String, dynamic>> emailTools = emailToolsDefinition.values.toList();

const Set<String> readOnlyFunctions = {
  'search_emails',
  'read_email',
  'list_inbox',
};

const Set<String> writeFunctions = {
  'send_email',
  'reply_to_email',
  'forward_email',
  'archive_email',
  'delete_email',
  'mark_as_read',
  'mark_as_unread',
};
