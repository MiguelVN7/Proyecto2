#!/bin/bash

echo "🔍 Diagnóstico de Conectividad Backend"
echo "======================================"
echo ""

# 1. Verificar que el backend esté corriendo
echo "1. Verificando que el backend esté corriendo..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "   ✅ Backend respondiendo en localhost:3000"
else
    echo "   ❌ Backend NO responde en localhost:3000"
    exit 1
fi

# 2. Verificar la IP de la red
echo ""
echo "2. IP de la red local:"
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
if [ -z "$LOCAL_IP" ]; then
    echo "   ⚠️  No se pudo detectar la IP automáticamente"
    echo "   Usa: ifconfig | grep 'inet ' para encontrarla manualmente"
else
    echo "   📍 IP detectada: $LOCAL_IP"
    
    # 3. Verificar que el backend sea accesible por IP
    echo ""
    echo "3. Verificando acceso por IP de red..."
    if curl -s "http://$LOCAL_IP:3000/health" > /dev/null; then
        echo "   ✅ Backend accesible en http://$LOCAL_IP:3000"
    else
        echo "   ❌ Backend NO accesible por IP de red"
        echo "   Posible problema de firewall o configuración de red"
    fi
fi

# 4. Verificar la configuración en la app
echo ""
echo "4. Verificando configuración de la app..."
APP_URL=$(grep -r "192.168.1" "/Users/miguelvillegas/Proyecto 2/frontend/lib/config/api_config.dart" 2>/dev/null | grep -o "192\.168\.[0-9]\+\.[0-9]\+" | head -1)
if [ -z "$APP_URL" ]; then
    echo "   ⚠️  No se encontró URL configurada en api_config.dart"
else
    echo "   📱 URL configurada en app: http://$APP_URL:3000"
    
    if [ "$APP_URL" != "$LOCAL_IP" ]; then
        echo "   ⚠️  WARNING: La IP en la app ($APP_URL) es diferente a la IP actual ($LOCAL_IP)"
        echo "   Necesitas actualizar api_config.dart con la IP correcta"
    else
        echo "   ✅ La IP en la app coincide con la IP actual"
    fi
fi

# 5. Ver últimos reportes en Firestore
echo ""
echo "5. Últimos reportes guardados:"
ls -lt "/Users/miguelvillegas/Proyecto 2/backend/reports" 2>/dev/null | head -5 || echo "   No hay reportes guardados"

echo ""
echo "======================================"
echo "Diagnóstico completado"
