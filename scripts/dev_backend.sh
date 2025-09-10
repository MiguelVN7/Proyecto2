#!/bin/bash

# EcoTrack - Script de Backend
# Inicia solo el servidor backend de forma persistente

echo "🔧 ECOTRACK - INICIANDO BACKEND..."

# Configuración
BACKEND_DIR="../backend"
BACKEND_LOG="../logs/backend.log"

# Crear directorio de logs si no existe
mkdir -p "../logs"

# Función para verificar si el backend está corriendo
check_backend() {
    if pgrep -f "node.*server.js" > /dev/null; then
        echo "✅ Backend está corriendo"
        return 0
    else
        echo "❌ Backend no está corriendo"
        return 1
    fi
}

# Función para verificar conectividad
check_connectivity() {
    if curl -s http://192.168.1.115:3000/health > /dev/null; then
        echo "✅ Backend responde correctamente"
        return 0
    else
        echo "❌ Backend no responde"
        return 1
    fi
}

# Detener cualquier instancia previa
echo "🛑 Deteniendo procesos previos..."
pkill -f "node.*server.js" 2>/dev/null || true

# Esperar un momento
sleep 2

echo "🖥️  INICIANDO BACKEND..."

# Ir al directorio del backend e iniciar
cd "$BACKEND_DIR" || exit 1

# Iniciar backend en segundo plano y guardar PID
echo "🌱 Iniciando servidor Node.js..."
nohup node server.js > "$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!

# Esperar un momento para que el servidor inicie
sleep 3

# Verificar que está corriendo
if check_backend; then
    echo "✅ Backend iniciado correctamente (PID: $BACKEND_PID)"
else
    echo "❌ Error al iniciar backend"
    exit 1
fi

# Verificar conectividad
echo "🔗 VERIFICANDO CONECTIVIDAD..."
sleep 2

if check_connectivity; then
    echo "🎉 ¡BACKEND LISTO!"
    echo "📊 Acceso: http://192.168.1.115:3000"
    echo "🔗 Health check: http://192.168.1.115:3000/health"
    echo "📝 API Reportes: http://192.168.1.115:3000/api/reports"
    echo "📋 PID: $BACKEND_PID"
    echo "📄 Log: $BACKEND_LOG"
    echo ""
    echo "💡 Para ver los logs en tiempo real:"
    echo "   tail -f $BACKEND_LOG"
    echo ""
    echo "🛑 Para detener el backend:"
    echo "   kill $BACKEND_PID"
else
    echo "❌ Backend no responde, revisando logs..."
    tail -10 "$BACKEND_LOG"
    exit 1
fi
