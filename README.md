# Riso

Cliente de chat de inteligencia artificial local y agente de automatización de correo electrónico para Android.

**100% local.** Sin servidores propios, sin telemetría, sin cuentas. Tu información nunca sale de tu dispositivo.

## Arquitectura

```
┌─────────────────────────────────────────────┐
│                   Riso                        │
│  ┌─────────────────────────────────────┐    │
│  │         Interfaz de Chat             │    │
│  │  (Material 3, Markdown, Streaming)   │    │
│  └──────────────┬──────────────────────┘    │
│                 │                            │
│  ┌──────────────▼──────────────────────┐    │
│  │        LLM Resolver                  │    │
│  │  Gemini │ OpenAI │ Claude            │    │
│  └──────────────┬──────────────────────┘    │
│                 │                            │
│  ┌──────────────▼──────────────────────┐    │
│  │     Function Calling Handler         │    │
│  │  (10 herramientas de correo)         │    │
│  └──┬───────────────┬──────────────────┘    │
│     │               │                        │
│  ┌──▼──────┐  ┌─────▼───────┐              │
│  │ Gmail   │  │ IMAP/SMTP   │              │
│  │ API     │  │ (Sockets)   │              │
│  └─────────┘  └─────────────┘              │
│                                            │
│  ┌─────────────────────────────────────┐    │
│  │     Almacenamiento Local             │    │
│  │  flutter_secure_storage (Keystore)   │    │
│  │  Hive cifrado (chats, config)        │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Principios

- **Zero-Cloud:** No hay servidores propios. Toda la lógica, procesamiento y almacenamiento ocurre en el dispositivo.
- **Privacidad:** Las API keys del usuario y tokens OAuth se almacenan en el hardware de cifrado del dispositivo (Android Keystore vía `flutter_secure_storage`).
- **Multi-LLM:** Soporte para Google Gemini, OpenAI GPT y Anthropic Claude intercambiables en tiempo de ejecución.
- **Modo Planificación:** Toggle global que bloquea acciones de escritura de la IA hasta que el usuario las apruebe.

## Requisitos

- **Docker Compose v2.20+** (recomendado) o
- **Flutter SDK** ≥3.7.0 + Android SDK 35 + Java 17 (para compilación local)

## Compilación

### Con Docker (recomendado)

```bash
# APK debug
docker-compose run --rm android-debug
# → dist/app-debug.apk

# APK release (requiere keystore)
export KEYSTORE_PASSWORD="tu-pass"
export KEY_PASSWORD="tu-pass"
docker-compose run --rm android-release
# → dist/app-release.apk
```

### Sin Docker (Flutter local)

```bash
flutter pub get
flutter build apk --debug
# o
flutter build apk --release
```

## Configuración

### API Keys (LLM)

Obtén tus propias API keys de los proveedores que quieras usar:

| Proveedor | Cómo obtener la key |
|-----------|-------------------|
| Google Gemini | https://aistudio.google.com/apikey |
| OpenAI | https://platform.openai.com/api-keys |
| Anthropic Claude | https://console.anthropic.com/ |

En la app: **Ajustes → API Keys** → ingresa tu key.

### Cuentas de Correo

#### Gmail

En **Ajustes → Cuentas de correo → Añadir cuenta → Gmail**, presiona el botón **"Iniciar sesión con Google"**. La app usará el flujo OAuth2 estándar de Android para pedir permiso y acceder a tu Gmail.

No necesitas crear proyectos en Google Cloud Console. `google_sign_in` maneja todo el flujo contra la cuenta de Google del usuario.

#### IMAP/SMTP (Outlook, Yahoo, corporativo)

En **Ajustes → Cuentas de correo → Añadir cuenta → IMAP/SMTP**, ingresa:
- Correo electrónico
- Contraseña (o contraseña de aplicación)
- Servidor IMAP (ej: `imap.outlook.com`)
- Servidor SMTP (ej: `smtp.outlook.com`)

## Uso

### Chat Multi-LLM

1. Presiona **"Nuevo chat"** y selecciona el proveedor (Gemini, OpenAI, Claude)
2. Escribe tu mensaje. La IA responde con formato Markdown.
3. El chat guarda el historial localmente.

### Modo Planificación

El botón flotante (escudo/rayo) alterna entre dos modos:

| Modo | Icono | Efecto |
|------|-------|--------|
| **Planificación** | 🛡️ | La IA solo puede leer correos; las acciones de escritura se bloquean y se muestran como plan |
| **Ejecución** | ⚡ | La IA ejecuta acciones automáticamente (enviar, archivar, eliminar) |

### Correo Electrónico

La IA puede gestionar tu correo mediante lenguaje natural:

- *"Busca correos de Juan sobre el proyecto"*
- *"¿Qué dice el último correo de María?"*
- *"Envía un correo a ana@empresa.com con asunto 'Reunión' y confirma que está bien"*
- *"Archiva todos los correos de ofertas"*
- *"Marca como leído el correo con asunto 'Factura'"*

### Herramientas disponibles (10 funciones)

| Función | Tipo | Descripción |
|---------|------|-------------|
| `list_inbox` | Lectura | Lista correos recientes |
| `search_emails` | Lectura | Busca correos por query |
| `read_email` | Lectura | Lee contenido de un correo |
| `send_email` | Escritura | Envía un nuevo correo |
| `reply_to_email` | Escritura | Responde a un correo |
| `forward_email` | Escritura | Reenvía un correo |
| `mark_as_read` | Escritura | Marca como leído |
| `mark_as_unread` | Escritura | Marca como no leído |
| `archive_email` | Escritura | Archiva un correo |
| `delete_email` | Escritura | Mueve a papelera |

### Respaldo 1-Click

**Exportar:** En **Ajustes → Respaldo y Restauración → Exportar respaldo**. Se genera un archivo ZIP con todos los chats y configuración (excepto API keys y contraseñas) y se abre la hoja de compartir de Android.

**Importar:** Presiona **Importar respaldo** y selecciona el archivo ZIP o JSON. Los datos se fusionan sin sobrescribir los existentes.

## Estructura del proyecto

```
lib/
├── core/               # Tema, constantes
├── features/
│   ├── chat/           # Chat multi-LLM
│   ├── email/          # Integración de correo
│   ├── settings/       # API keys, configuración
│   └── backup/         # Exportar/Importar
├── models/             # Modelos de datos
├── providers/          # Estado (Riverpod)
├── services/
│   ├── llm/            # Gemini, OpenAI, Claude
│   ├── email/          # Gmail API, IMAP/SMTP
│   └── storage/        # SecureStorage, Hive
└── widgets/            # Componentes reutilizables
```

## Docker

```bash
docker-compose run --rm android-debug    # Debug APK
docker-compose run --rm android-release   # Release APK
```

Variables de entorno para release: `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.

## Licencia

**GNU Affero General Public License v3.0** — ver [`LICENSE`](LICENSE).

Esto significa que puedes usar, modificar y distribuir el código, pero si ofreces un servicio en red basado en esta aplicación, debes publicar el código fuente modificado bajo la misma licencia.
