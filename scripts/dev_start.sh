#!/bin/bash

# 🚀 EcoTrack - Script de Desarrollo Completo
# Maneja tanto Frontend como Backend

set -e

DEVICE_ID=${1:-"28542161b23f7ece"}
APP_ID="com.example.eco_track"

echo "🌱 ECOTRACK - INICIANDO ENTORNO COMPLETO..."

# Función para verificar si un proceso está corriendo
check_process() {
    if pgrep -f "$1" > /dev/null; then
        echo "✅ $1 está corriendo"
        return 0
    else
        echo "❌ $1 no está corriendo"
        return 1
    fi
}

# 1. INICIAR BACKEND
echo ""
echo "🖥️  INICIANDO BACKEND..."
cd backend

if ! check_process "node.*server.js"; then
    echo "📦 Instalando dependencias del backend..."
    npm install
    
    echo "🚀 Iniciando servidor backend..."
    nohup npm start > ../logs/backend.log 2>&1 &
    sleep 3
    
    if check_process "node.*server.js"; then
        echo "✅ Backend iniciado correctamente en puerto 3000"
    else
        echo "❌ Error al iniciar backend"
        exit 1
    fi
else
    echo "✅ Backend ya está corriendo"
fi

cd ..

# 2. VERIFICAR CONECTIVIDAD
echo ""
echo "🔗 VERIFICANDO CONECTIVIDAD..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Backend responde correctamente"
else
    echo "❌ Backend no responde"
    exit 1
fi

# 3. PREPARAR FRONTEND
echo ""
echo "📱 PREPARANDO FRONTEND..."
cd frontend

echo "🧹 Limpiando cache..."
adb uninstall $APP_ID || echo "App no estaba instalada"
flutter clean
cd android && ./gradlew clean && cd ..

echo "📦 Instalando dependencias..."
flutter pub get

# Incrementar versión
echo "📊 Incrementando versión..."
CURRENT_VERSION=$(grep "version:" pubspec.yaml | cut -d'+' -f2)
NEW_VERSION=$((CURRENT_VERSION + 1))
sed -i '' "s/version: 1.0.0+$CURRENT_VERSION/version: 1.0.0+$NEW_VERSION/" pubspec.yaml

echo "✅ Nueva versión: 1.0.0+$NEW_VERSION"

echo "🚀 Desplegando aplicación..."
flutter run -d $DEVICE_ID

cd ..

echo ""
echo "🎉 ENTORNO COMPLETO INICIADO EXITOSAMENTE!"
echo "📱 Frontend: Flutter app en dispositivo $DEVICE_ID"
echo "🖥️  Backend: http://localhost:3000"
echo "📊 Versión: 1.0.0+$NEW_VERSION"
