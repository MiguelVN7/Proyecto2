#!/bin/bash

# EcoTrack - Script de Frontend
# Inicia solo la aplicación Flutter

echo "📱 ECOTRACK - INICIANDO FRONTEND..."

# Configuración
FRONTEND_DIR="../frontend"

# Función para verificar si hay dispositivos conectados
check_devices() {
    cd "$FRONTEND_DIR" || exit 1
    
    echo "🔍 Verificando dispositivos Flutter..."
    flutter devices --machine | grep -q '"id"'
    
    if [ $? -eq 0 ]; then
        echo "✅ Dispositivos encontrados:"
        flutter devices
        return 0
    else
        echo "❌ No hay dispositivos conectados"
        echo "💡 Conecta un dispositivo Android o inicia un emulador"
        return 1
    fi
}

# Verificar dispositivos
if ! check_devices; then
    exit 1
fi

# Ir al directorio del frontend
cd "$FRONTEND_DIR" || exit 1

echo "📱 INICIANDO APLICACIÓN FLUTTER..."
echo "🔥 Hot reload habilitado - presiona 'r' para recargar"
echo "🛑 Presiona 'q' para salir"
echo ""

# Iniciar Flutter
flutter run
