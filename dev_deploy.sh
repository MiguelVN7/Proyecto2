#!/bin/bash

# 🚀 EcoTrack - Script de Desarrollo Limpio
# Uso: ./dev_deploy.sh [device_id]

set -e  # Salir si hay errores

DEVICE_ID=${1:-"28542161b23f7ece"}
APP_ID="com.example.eco_track"

echo "🧹 LIMPIANDO ENTORNO DE DESARROLLO..."

# 1. Desinstalar app del dispositivo
echo "📱 Desinstalando app del dispositivo..."
adb uninstall $APP_ID || echo "App no estaba instalada"

# 2. Limpiar cache de Flutter
echo "🔄 Limpiando cache de Flutter..."
flutter clean

# 3. Limpiar cache de Gradle (Android)
echo "🔄 Limpiando cache de Gradle..."
cd android
./gradlew clean
cd ..

# 4. Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# 5. Incrementar versión automáticamente
echo "📊 Incrementando versión..."
CURRENT_VERSION=$(grep "version:" pubspec.yaml | cut -d'+' -f2)
NEW_VERSION=$((CURRENT_VERSION + 1))
sed -i '' "s/version: 1.0.0+$CURRENT_VERSION/version: 1.0.0+$NEW_VERSION/" pubspec.yaml

echo "✅ Nueva versión: 1.0.0+$NEW_VERSION"

# 6. Instalar y ejecutar
echo "🚀 Desplegando aplicación..."
flutter run -d $DEVICE_ID

echo "✅ DESPLIEGUE COMPLETADO CON ÉXITO!"
