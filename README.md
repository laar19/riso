# Riso

Cliente de chat de IA local y agente de automatización de correo electrónico para Android.

## Arquitectura

- 100% local — sin servidores propios
- Multi-LLM: Gemini, OpenAI, Claude
- Integración de correo vía Function Calling (Gmail API + IMAP/SMTP)
- Modo Planificación (solo lectura) / Modo Ejecución
- Respaldo 1-Click (exportar/importar en JSON/ZIP)

## Compilación con Docker

### Requisitos

- Docker Compose v2.20+

### Compilar APK Debug

```bash
docker-compose run --rm android-debug
```

El APK se genera en `./dist/app-debug.apk`.

### Compilar APK Release

Coloca tu archivo keystore en `./keystore/upload-keystore.jks` y ejecuta:

```bash
KEYSTORE_PASSWORD="tu-pass" \
KEY_PASSWORD="tu-pass" \
KEY_ALIAS="upload" \
docker-compose run --rm android-release
```

O usa variables de entorno desde un archivo `.env`:

```env
KEYSTORE_PATH=/keystore/upload-keystore.jks
KEYSTORE_PASSWORD=tu-pass
KEY_ALIAS=upload
KEY_PASSWORD=tu-pass
```

### Compilación sin Docker (Flutter local)

```bash
flutter pub get
flutter build apk --debug
# o
flutter build apk --release
```

## Variables de Entorno (Release)

| Variable | Descripción |
|---|---|
| `KEYSTORE_PATH` | Ruta al keystore dentro del contenedor |
| `KEYSTORE_PASSWORD` | Contraseña del keystore |
| `KEY_ALIAS` | Alias de la clave de firma |
| `KEY_PASSWORD` | Contraseña de la clave de firma |

## Estructura del Proyecto

```
riso/
├── lib/
│   ├── core/           # Tema, constantes, utilerías
│   ├── features/
│   │   ├── chat/       # Interfaz de chat multi-LLM
│   │   ├── email/      # Integración de correo
│   │   ├── settings/   # Configuración de API keys
│   │   └── backup/     # Exportar/Importar
│   ├── models/         # Modelos de datos
│   ├── providers/      # Estado global (Riverpod)
│   ├── services/       # LLM y servicios de correo
│   └── widgets/        # Componentes reutilizables
├── android/            # Plataforma Android
├── dist/               # APKs compilados
├── Dockerfile          # Imagen de compilación
└── docker-compose.yml  # Perfiles debug/release
```
