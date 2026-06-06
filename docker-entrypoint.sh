#!/bin/bash
set -e

KEYSTORE_PATH="${KEYSTORE_PATH:-/keystore/upload-keystore.jks}"

if [ -f "$KEYSTORE_PATH" ]; then
  echo "Keystore encontrado en $KEYSTORE_PATH — configurando firma..."

  mkdir -p android/app

  cat > android/key.properties <<EOF
storePassword=${KEYSTORE_PASSWORD:-}
keyPassword=${KEY_PASSWORD:-}
keyAlias=${KEY_ALIAS:-upload}
storeFile=$KEYSTORE_PATH
EOF

  echo "Firma configurada correctamente."
else
  echo "AVISO: No se encontró keystore en $KEYSTORE_PATH"
  echo "El APK se compilará sin firmar (usa signingConfigs.debug)."
fi

exec flutter build apk --release --output=dist/app-release.apk
