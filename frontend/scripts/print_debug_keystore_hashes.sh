#!/usr/bin/env bash
set -euo pipefail
KEYSTORE="${HOME}/.android/debug.keystore"
ALIAS="AndroidDebugKey"
STOREPASS="android"
KEYPASS="android"
if [ ! -f "$KEYSTORE" ]; then
  echo "No se encontró el keystore debug en $KEYSTORE" >&2
  exit 1
fi
JAVA_HOME_CMD=$(command -v keytool >/dev/null 2>&1 && echo "" || /usr/libexec/java_home)
if [ -z "$JAVA_HOME_CMD" ]; then
  KEYTOOL=$(command -v keytool)
else
  KEYTOOL="$JAVA_HOME_CMD/bin/keytool"
fi
if [ ! -x "$KEYTOOL" ]; then
  echo "No se encontró keytool. Asegúrate de tener un JDK instalado." >&2
  exit 2
fi
$KEYTOOL -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$STOREPASS" -keypass "$KEYPASS" 2>/dev/null | \
  grep -E 'SHA1:|SHA-256:' | sed 's/^[[:space:]]*//' 
